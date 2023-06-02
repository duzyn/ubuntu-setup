#!/usr/bin/env bash
# Based on https://github.com/devstructure/ubuntu and
# https://github.com/covertsh/ubuntu-preseed-iso-generator


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
: "${ISO_FILE:="$(basename "$ISO_URL")"}"
: "${ISO_DIST_DIR="dist"}"

# Hardcoded host information.
: "${ISO_USERNAME:="john"}"
: "${ISO_PASSWORD:="111111"}"
: "${ISO_FULL_NAME:="John Doe"}"
: "${ISO_HOST:="xubuntu"}"
: "${ISO_DOMAIN:="xubuntu.guest.virtualbox.org"}"
: "${ISO_LOCALE:="zh_CN"}"
: "${ISO_TIMEZONE:="Asia/Shanghai"}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TMPDIR="$(mktemp -d)"

if eval "wget --show-progress -qO- $(dirname "$ISO_URL")/SHA256SUMS" >> /dev/null 2>&1; then
    SHA256SUMS_URL=$(dirname "$ISO_URL")/SHA256SUMS # Ubuntu
elif eval "wget --show-progress -qO- $(dirname "$ISO_URL")/sha256sum.txt" >> /dev/null 2>&1; then
    SHA256SUMS_URL=$(dirname "$ISO_URL")/sha256sum.txt # Linux Mint
else
    echo "Failed! No SHA256SUMS available." && exit 1
fi

# Do things in a tmp directory
if [[ ! "$TMPDIR" ]] || [[ ! -d "$TMPDIR" ]]; then
    echo "Could not create temporary working directory."
else
    echo "Created temporary working directory $TMPDIR."
fi

# Utilities should installed before run this script
echo "Checking required utilities..."
[[ ! -x "$(command -v wget)" ]] && echo "wget is not installed." && exit 1
[[ ! -x "$(command -v sed)" ]] && echo "sed is not installed." && exit 1
[[ ! -x "$(command -v xorriso)" ]] && echo "xorriso is not installed." && exit 1
[[ ! -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]] && echo "isolinux is not installed." && exit 1
echo "All required utilities are installed."

# Download ISO file
if [[ -f "$ISO_FILE" ]]; then
    echo "Using existing $ISO_FILE..."
else
    echo "Downloading $ISO_FILE..."
    wget --show-progress -O "$ISO_FILE" "$ISO_URL"
fi

# Check SHA256SUMS
echo "Verifying ISO file..."
if [[ "$(wget --show-progress -qO- "$SHA256SUMS_URL" | grep "$ISO_FILE" | cut -f1 -d " ")" == "$(sha256sum "$ISO_FILE" | cut -f1 -d " ")" ]]; then
    echo "ISO file is verified."
else
    echo "ISO file verification is failed, please download the file again!" && exit 1
fi

# Extract Ubuntu ISO image
echo "Extracting Ubuntu ISO image to $TMPDIR..."
xorriso -osirrox on -indev "$ISO_FILE" -extract / "$TMPDIR" &>/dev/null
chmod -R u+w "$TMPDIR"
rm -rf "$TMPDIR/"'[BOOT]'

echo "Adding preseed parameters to kernel command line..."
# These are for UEFI mode
sed -i -e "s|file=/cdrom/preseed/.*\.seed.*\-\-$|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell --|g" \
    "$TMPDIR/boot/grub/grub.cfg"
sed -i -e "s|file=/cdrom/preseed/.*\.seed.*\-\-$|file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell --|g" \
    "$TMPDIR/boot/grub/loopback.cfg"
sed -i -e '/timeout=/d' "$TMPDIR/boot/grub/grub.cfg"
echo -e "\nset timeout=3\n">>"$TMPDIR/boot/grub/grub.cfg"

# This one is used for BIOS mode
cat <<EOF >"$TMPDIR/isolinux/txt.cfg"
default custom-install
timeout 1
label custom-install
  menu label ^Auto Install
  kernel /casper/vmlinuz
  append file=/cdrom/preseed/custom.seed auto=true priority=critical boot=casper automatic-ubiquity initrd=/casper/initrd quiet splash noprompt noshell ---
EOF

# Preseed reference:
# https://d-i.debian.org/manual/zh_CN.amd64/apb.html
# https://github.com/covertsh/ubuntu-preseed-iso-generator/blob/main/example.seed
# https://superuser.com/questions/1544921/vboxmanage-unattended-ubuntu-live-server/1545412#1545412
echo "Adding preseed configuration file..."
cat <<EOF >"$TMPDIR/preseed/custom.seed"
# Locale
d-i debian-installer/locale string $ISO_LOCALE.UTF-8
d-i keyboard-configuration/layoutcode string us
d-i keyboard-configuration/xkb-keymap select us

ubiquity ubiquity/use_nonfree boolean true

# Network
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string $ISO_HOST
d-i netcfg/get_domain string $ISO_DOMAIN
d-i netcfg/wireless_wep string

# Clock
d-i time/zone string $ISO_TIMEZONE
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true

# Users
d-i passwd/user-fullname string $ISO_FULL_NAME
d-i passwd/username string $ISO_USERNAME
d-i passwd/user-password ISO_password $ISO_PASSWORD
d-i passwd/user-password-again ISO_password $ISO_PASSWORD
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

echo "Updating $TMPDIR/md5sum.txt with hashes of modified files..."
if [[ -f "$TMPDIR/md5sum.txt" ]]; then # Ubuntu 20.04
    MD5FILE="$TMPDIR/md5sum.txt"
elif [[ -f "$TMPDIR/MD5SUMS" ]]; then # Linux Mint 21.1
    MD5FILE="$TMPDIR/MD5SUMS"
fi
sed -i -e '/.\/boot\/grub\/grub.cfg/d' -e '/.\/boot\/grub\/loopback.cfg/d' "$MD5FILE"
{
    echo "$(md5sum "$TMPDIR/boot/grub/grub.cfg"      | cut -f1 -d " ")  ./boot/grub/grub.cfg"
    echo "$(md5sum "$TMPDIR/boot/grub/loopback.cfg"  | cut -f1 -d " ")  ./boot/grub/loopback.cfg"
    echo "$(md5sum "$TMPDIR/preseed/custom.seed"     | cut -f1 -d " ")  ./preseed/custom.seed"
    echo "$(md5sum "$TMPDIR/isolinux/txt.cfg"        | cut -f1 -d " ")  ./isolinux/txt.cfg"
} >>"$MD5FILE"

echo "Repackaging extracted files into an ISO image..."
cd "$TMPDIR"
mkdir -p "$SCRIPT_DIR/$ISO_DIST_DIR"
xorriso -as mkisofs -r -V "Ubuntu Custom" -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -boot-info-table -input-charset utf-8 -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -o "$SCRIPT_DIR/$ISO_DIST_DIR/$ISO_FILE" . &>/dev/null
cd "$OLDPWD"
echo "Repackaged into $SCRIPT_DIR/$ISO_DIST_DIR/$ISO_FILE."

echo "Completed." && exit 0
