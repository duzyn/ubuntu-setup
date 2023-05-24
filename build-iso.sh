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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
. "$SCRIPT_DIR/config.sh"
BUILT_ISO="$SCRIPT_DIR/${SOURCE_ISO%.*}-custom.iso"
TMPDIR="$(mktemp -d)"

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



# Do things in a tmp directory
if [[ ! "$TMPDIR" ]] || [[ ! -d "$TMPDIR" ]]; then
    die "Could not create temporary working directory."
else
    log "Created temporary working directory $TMPDIR."
fi

# Utilities should installed before run this script
log "Checking required utilities..."
[[ ! -x "$(command -v wget)" ]] && die "wget is not installed."
[[ ! -x "$(command -v xorriso)" ]] && die "xorriso is not installed."
[[ ! -x "$(command -v sed)" ]] && die "sed is not installed."
[[ ! -x "$(command -v m4)" ]] && die "m4 is not installed."
[[ ! -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]] && die "isolinux is not installed."
log "All required utilities are installed."

# Download ISO file
if [[ -f "$SOURCE_ISO" ]]; then
    log "Using existing $SOURCE_ISO..."
else
    log "Downloading $SOURCE_ISO..."
    wget -qO "$SOURCE_ISO" "$ISO_URL"
fi

# Check SHA256SUMS
if [[ "$(sha256sum "$SOURCE_ISO" | cut -f1 -d " ")" == "$(wget -qO- "$(dirname "$ISO_URL")/SHA256SUMS" | grep "$SOURCE_ISO" | cut -f1 -d " ")" ]]; then
    log "ISO file is verified."
else
    die "ISO file verification is failed, please redownload the file!"
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

log "Adding preseed configuration file..."
m4 -D __USERNAME__="$USERNAME" \
    -D __PASSWORD__="$PASSWORD" \
    -D __FULLNAME__="$FULLNAME" \
    -D __HOST__="$HOST" \
    -D __DOMAIN__="$DOMAIN" \
    -D __LOCALE__="$LOCALE" \
    -D __TIMEZONE__="$TIMEZONE" \
    "custom.seed.m4.cfg" >"$TMPDIR/preseed/custom.seed"

log "Updating $TMPDIR/md5sum.txt with hashes of modified files..."
sed -i -e '/.\/boot\/grub\/grub.cfg/d' \
    -e '/.\/boot\/grub\/loopback.cfg/d' \
    "$TMPDIR/md5sum.txt"
{
    echo "$(md5sum "$TMPDIR/boot/grub/grub.cfg"      | cut -f1 -d " ")  ./boot/grub/grub.cfg"
    echo "$(md5sum "$TMPDIR/boot/grub/loopback.cfg"  | cut -f1 -d " ")  ./boot/grub/loopback.cfg"
    echo "$(md5sum "$TMPDIR/preseed/custom.seed"     | cut -f1 -d " ")  ./preseed/custom.seed"
} >>"$TMPDIR/md5sum.txt"

log "Repackaging extracted files into an ISO image..."
cd "$TMPDIR"
xorriso -as mkisofs -r -V "Ubuntu Custom" -J \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -boot-info-table -input-charset utf-8 -eltorito-alt-boot \
    -e boot/grub/efi.img -no-emul-boot -isohybrid-gpt-basdat \
    -o "$BUILT_ISO" . &>/dev/null
cd "$OLDPWD"
log "Repackaged into $BUILT_ISO."

die "Completed." 0
