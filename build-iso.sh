#!/usr/bin/env bash
# Based on https://github.com/devstructure/ubuntu and
# https://github.com/covertsh/ubuntu-preseed-iso-generator
# Ubuntu has discontinued preseed as of 20.04 according to this:
# https://discourse.ubuntu.com/t/server-installer-plans-for-20-04-lts/13631


# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
: "${DEBUG="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace

# Arguments given to the download router.
: "${ISO_URL:="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso"}"
: "${SOURCE_ISO:="$(basename "$ISO_URL")"}"
: "${DIST_DIR="dist"}"

# Hardcoded host information.
: "${USERNAME:="john"}"
: "${PASSWORD:="111111"}"
: "${FULL_NAME:="John Doe"}"
: "${HOST:="xubuntu"}"
: "${DOMAIN:="xubuntu.guest.virtualbox.org"}"
: "${LOCALE:="zh_CN"}"
: "${TIMEZONE:="Asia/Shanghai"}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TMPDIR="$(mktemp -d)"

[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1

function log() {
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
    local msg=$1
    local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    log "$msg"
    exit "$code"
}



# Do things in a tmp directory
if [[ ! "$TMPDIR" ]] || [[ ! -d "$TMPDIR" ]]; then
    die "Could not create temporary working directory."
else
    log "Created temporary working directory $TMPDIR."
fi

# Utilities should installed before run this script
log "Checking required utilities..."
[[ ! -x "$(command -v wget)" ]] && die "wget is not installed."
[[ ! -x "$(command -v sed)" ]] && die "sed is not installed."
[[ ! -x "$(command -v xorriso)" ]] && die "xorriso is not installed."
[[ ! -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]] && die "isolinux is not installed."
log "All required utilities are installed."

# Download ISO file
if [[ -f "$SOURCE_ISO" ]]; then
    log "Using existing $SOURCE_ISO..."
else
    log "Downloading $SOURCE_ISO..."
    wget -O "$SOURCE_ISO" "$ISO_URL"
    log "Downloaded $SOURCE_ISO."
fi

# Check SHA256SUMS
log "Verifying ISO file..."
if [[ "$(sha256sum "$SOURCE_ISO" | cut -f1 -d " ")" == "$(wget -qO- "$(dirname "$ISO_URL")/SHA256SUMS" | grep "$SOURCE_ISO" | cut -f1 -d " ")" ]]; then
    log "ISO file is verified."
else
    die "ISO file verification is failed, please download the file again!"
fi

# Extract Ubuntu ISO image
log "Extracting Ubuntu ISO image to $TMPDIR..."
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$TMPDIR" &>/dev/null
chmod -R u+w "$TMPDIR"
rm -rf "$TMPDIR/"'[BOOT]'

log "Adding preseed parameters to kernel command line..."
# These are for UEFI mode
# Ubuntu
sed -i -e "s|file=/cdrom/preseed/ubuntu.seed maybe-ubiquity quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    "$TMPDIR/boot/grub/grub.cfg"
sed -i -e "s|file=/cdrom/preseed/ubuntu.seed maybe-ubiquity iso-scan/filename=\${iso_path} quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    "$TMPDIR/boot/grub/loopback.cfg"
# Xubuntu
sed -i -e "s|file=/cdrom/preseed/xubuntu.seed quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    -e "s|file=/cdrom/preseed/xubuntu.seed only-ubiquity quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    "$TMPDIR/boot/grub/grub.cfg"
sed -i -e "s|file=/cdrom/preseed/xubuntu.seed iso-scan/filename=\${iso_path} quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    -e "s|file=/cdrom/preseed/xubuntu.seed only-ubiquity iso-scan/filename=\${iso_path} quiet splash|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell|g" \
    "$TMPDIR/boot/grub/loopback.cfg"

# This one is used for BIOS mode
cat <<EOF >"$TMPDIR/isolinux/txt.cfg"
default custom-install
timeout 1
label custom-install
  menu label ^Install Ubuntu
  kernel /casper/vmlinuz
  append file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity initrd=/casper/initrd quiet splash noprompt noshell ---
EOF

# Preseed reference:
# https://d-i.debian.org/manual/zh_CN.amd64/apb.html
# https://github.com/covertsh/ubuntu-preseed-iso-generator/blob/main/example.seed
# https://superuser.com/questions/1544921/vboxmanage-unattended-ubuntu-live-server/1545412#1545412
log "Adding preseed configuration file..."
cat <<EOF >"$TMPDIR/preseed/custom.seed"
# Locale
d-i debian-installer/locale string $LOCALE.UTF-8
d-i keyboard-configuration/layoutcode string us
d-i keyboard-configuration/xkb-keymap select us

# Network
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string $HOST
d-i netcfg/get_domain string $DOMAIN
d-i netcfg/wireless_wep string

# Clock
d-i time/zone string $TIMEZONE
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true

# Users
d-i passwd/user-fullname string $FULL_NAME
d-i passwd/username string $USERNAME
d-i passwd/user-password password $PASSWORD
d-i passwd/user-password-again password $PASSWORD
d-i passwd/root-login boolean false
d-i user-setup/allow-password-weak boolean true

# Partitions
d-i partman-auto/method string lvm
d-i partman-auto-lvm/guided_size string max
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman-md/confirm boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# Grub and reboot
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i finish-install/reboot_in_progress note

# Custom Commands
# Ubuntu use ubiquity ubiquity/success_command instead of d-i preseed/late_command
# ubiquity ubiquity/success_command string postinstall.sh

# Reboot virtual machine after installation, so we can ssh connect to it to continue.
# If you use to install on a local pc, you may prefer power off instead of reboot.
ubiquity ubiquity/reboot boolean true

# Power off after install
# ubiquity ubiquity/poweroff boolean true
EOF

log "Updating $TMPDIR/md5sum.txt with hashes of modified files..."
sed -i -e '/.\/boot\/grub\/grub.cfg/d' -e '/.\/boot\/grub\/loopback.cfg/d' "$TMPDIR/md5sum.txt"
{
    echo "$(md5sum "$TMPDIR/boot/grub/grub.cfg"      | cut -f1 -d " ")  ./boot/grub/grub.cfg"
    echo "$(md5sum "$TMPDIR/boot/grub/loopback.cfg"  | cut -f1 -d " ")  ./boot/grub/loopback.cfg"
    echo "$(md5sum "$TMPDIR/preseed/custom.seed"     | cut -f1 -d " ")  ./preseed/custom.seed"
} >>"$TMPDIR/md5sum.txt"

log "Repackaging extracted files into an ISO image..."
cd "$TMPDIR"
[[ -d "$SCRIPT_DIR/$DIST_DIR" ]] || mkdir "$SCRIPT_DIR/$DIST_DIR"
xorriso -as mkisofs -r -V "Ubuntu Custom" -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -boot-info-table -input-charset utf-8 -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -o "$SCRIPT_DIR/$DIST_DIR/$SOURCE_ISO" . &>/dev/null
cd "$OLDPWD"
log "Repackaged into $SCRIPT_DIR/$DIST_DIR/$SOURCE_ISO."

die "Completed." 0
