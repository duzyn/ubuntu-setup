#!/usr/bin/env bash
# Inspired by https://github.com/devstructure/ubuntu

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

# VirtualBox
if [[ "$(uname -a)" =~ "WSL" ]]; then
    VBOXMANAGE_CMD="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
elif [[ "$(uname -a)" =~ "Linux" ]]; then
    VBOXMANAGE_CMD="/usr/bin/VBoxManage"
elif [[ "$(uname -a)" =~ "Darwin" ]]; then
    VBOXMANAGE_CMD="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"
else
    die "This script doesn't support the OS you are running."
fi


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

cd "$SCRIPT_DIR"

# Manual: https://docs.oracle.com/en/virtualization/virtualbox/7.0/user/vboxmanage.html#vboxmanage
if [[ "$("$VBOXMANAGE_CMD" list vms)" =~ $VBOX_NAME ]]; then
    log "You have created $VBOX_NAME, just boot it in VirtualBox."
else
    log "Creating Virtual Machine..."
    "$VBOXMANAGE_CMD" createvm \
        --name="$VBOX_NAME" \
        --ostype="$VBOX_OS_TYPE" \
        --register

    # Using SSH in WSL, Linux guest VM's network should be configured to accept external request.
    # Bridge should work, while NAT with port forwarding doesn't.
    "$VBOXMANAGE_CMD" modifyvm "$VBOX_NAME" \
        --cpus="$VBOX_CPU_NUMBER" \
        --memory="$VBOX_MEMORY" \
        --vram="$VBOX_VRAM" \
        --graphicscontroller=vmsvga \
        --accelerate3d=on \
        --nic1=nat \
        --firmware=efi \
        --boot1=dvd \
        --boot2=disk \
        --boot3=none \
        --boot4=none

    "$VBOXMANAGE_CMD" createmedium disk \
        --filename="$DIST_DIR/$VBOX_NAME/$VBOX_NAME.${VBOX_HDD_FORMAT,,}" \
        --size="$VBOX_HDD_SIZE" \
        --format="$VBOX_HDD_FORMAT" \
        --variant=Fixed
    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" \
        --name=SATA \
        --add=sata \
        --controller=IntelAhci
    "$VBOXMANAGE_CMD" storageattach "$VBOX_NAME" \
        --storagectl=SATA \
        --port=0 \
        --device=0 \
        --type=hdd \
        --medium="$DIST_DIR/$VBOX_NAME/$VBOX_NAME.${VBOX_HDD_FORMAT,,}"
    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" \
        --name=IDE \
        --add=ide \
        --controller=PIIX4
    "$VBOXMANAGE_CMD" storageattach "$VBOX_NAME" \
        --storagectl=IDE \
        --port=1 \
        --device=0 \
        --type=dvddrive \
        --medium="$DIST_DIR/$SOURCE_ISO"
fi

cd "$OLDPWD"

# Start the virtual machine and the OS installation.
if [[ "$("$VBOXMANAGE_CMD" list runningvms)" =~ $VBOX_NAME ]]; then
    log "Virtual machine $VBOX_NAME is running..."
else
    log "Starting Virtual machine $VBOX_NAME..."
    "$VBOXMANAGE_CMD" startvm "$VBOX_NAME" --type=gui
fi

die "Completed!" 0
