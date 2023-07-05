#!/usr/bin/env bash
# Based on https://github.com/devstructure/Debian and
# https://github.com/covertsh/Debian-preseed-iso-generator


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

# Hardcoded host information.
: "${USERNAME:="debian"}"
: "${PASSWORD:="debian"}"
: "${FULL_NAME:="debian"}"
: "${HOST:="debian"}"
: "${DOMAIN:="debian"}"
: "${LOCALE:="en_US"}"
: "${TIMEZONE:="America/Nome"}"

SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"
TMPDIR="$(mktemp -d)"
SOURCE_ISO=$1
DIST_ISO="${SOURCE_ISO%.*}-auto.iso"

[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1

function log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
    local msg=$1
    local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    log "$msg"
    exit "$code"
}

if [[ -z $1 || ! -e $1 ]]; then
    die "No source ISO file found."
fi

# Do things in a tmp directory
if [[ ! "$TMPDIR" ]] || [[ ! -d "$TMPDIR" ]]; then
    die "Could not create temporary working directory."
else
    log "Created temporary working directory $TMPDIR."
fi

# Utilities should installed before run this script
log "Checking required utilities..."
[[ ! -x "$(command -v xorriso)" ]] && die "xorriso is not installed."
[[ ! -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]] && die "isolinux is not installed."
log "All required utilities are installed."

# Extract Debian ISO image
log "Extracting Debian ISO image to $TMPDIR..."
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$TMPDIR" &>/dev/null
chmod -R u+w "$TMPDIR"
# rm -rf "$TMPDIR/"'[BOOT]'

log "Adding preseed parameters to kernel command line..."
# These are for UEFI mode
tee "$TMPDIR/boot/grub/grub.cfg" <<EOF
set timeout=1
set default=0
menuentry "auto" {
    linux  /install/vmlinuz vga=normal --- quiet auto=true file=/cdrom/custom.seed
    initrd /install/initrd.gz
}
EOF

# This one is used for BIOS mode
tee "$TMPDIR/isolinux/isolinux.cfg" <<EOF
timeout 1
default auto
label auto
    menu label ^auto
    kernel /install/vmlinuz
    append initrd=/install/initrd.gz --- quiet auto=true file=/cdrom/custom.seed
EOF

# Preseed reference:
# https://d-i.debian.org/manual/zh_CN.amd64/apb.html
# https://d-i.debian.org/manual/example-preseed.txt
log "Adding preseed configuration file..."
tee "$TMPDIR/custom.seed" <<EOF
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

# Apt setup
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/non-free-firmware boolean true
d-i apt-setup/non-free boolean true
d-i apt-setup/contrib boolean true
d-i apt-setup/disable-cdrom-entries boolean true
d-i apt-setup/use_mirror boolean false

# Grub and reboot
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i finish-install/reboot_in_progress note

# Custom Commands
# d-i preseed/late_command string apt-install zsh; in-target chsh -s /bin/zsh

# Reboot virtual machine after installation, so we can ssh connect to it to continue.
# If you use to install on a local pc, you may prefer power off instead of reboot.
# d-i debian-installer/exit/poweroff boolean true
EOF

log "Updating $TMPDIR/md5sum.txt with hashes of modified files..."
sed -i -e '/.\/boot\/grub\/grub.cfg/d' -e '/.\/isolinux\/isolinux.cfg/d' "$TMPDIR/md5sum.txt"
{
    echo "$(md5sum "$TMPDIR/boot/grub/grub.cfg"    | cut -f1 -d " ")  ./boot/grub/grub.cfg"
    echo "$(md5sum "$TMPDIR/isolinux/isolinux.cfg" | cut -f1 -d " ")  ./isolinux/isolinux.cfg"
    echo "$(md5sum "$TMPDIR/custom.seed"           | cut -f1 -d " ")  ./custom.seed"
} >>"$TMPDIR/md5sum.txt"

sed -i -e '/.\/boot\/grub\/grub.cfg/d' -e '/.\/isolinux\/isolinux.cfg/d' "$TMPDIR/sha256sum.txt"
{
    echo "$(sha256sum "$TMPDIR/boot/grub/grub.cfg"    | cut -f1 -d " ")  ./boot/grub/grub.cfg"
    echo "$(sha256sum "$TMPDIR/isolinux/isolinux.cfg" | cut -f1 -d " ")  ./isolinux/isolinux.cfg"
    echo "$(sha256sum "$TMPDIR/custom.seed"           | cut -f1 -d " ")  ./custom.seed"
} >>"$TMPDIR/sha256sum.txt"

log "Repackaging extracted files into an ISO image..."
cd "$TMPDIR"
xorriso -as mkisofs -r -V "Debian Custom" -J \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -boot-info-table -input-charset utf-8 -eltorito-alt-boot \
    -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat \
    -o "$SCRIPT_DIR/$DIST_ISO" . &>/dev/null
cd "$OLDPWD"
log "Repackaged into $SCRIPT_DIR/$DIST_ISO."

rm -rf "$TMPDIR"
die "Completed." 0
