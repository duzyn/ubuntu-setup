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

# Arguments given to the download router.
: "${ISO_URL:="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso"}"
: "${ISO_FILE:="$(basename "$ISO_URL")"}"
: "${ISO_DIST_DIR="dist"}"

# Virtual machine
: "${VBOX_NAME:="${ISO_FILE%.*}"}"
: "${VBOX_OS_TYPE:=Ubuntu_64}"
: "${VBOX_CPU_NUMBER:=2}"
: "${VBOX_MEMORY:=2048}"
: "${VBOX_VRAM:=128}"
: "${VBOX_HDD_SIZE:=61440}"
: "${VBOX_HDD_FORMAT:=VDI}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# VirtualBox
if [[ "$(uname -a)" =~ "WSL" ]]; then
    VBOXMANAGE_CMD="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
elif [[ "$(uname -a)" =~ "Linux" ]]; then
    VBOXMANAGE_CMD="/usr/bin/VBoxManage"
elif [[ "$(uname -a)" =~ "Darwin" ]]; then
    VBOXMANAGE_CMD="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"
else
    echo "This script doesn't support the OS you are running." && exit 1
fi

[[ ! -f "$VBOXMANAGE_CMD" ]] && echo "VirtualBox is not installed." && exit 1


cd "$SCRIPT_DIR"

# Manual: https://docs.oracle.com/en/virtualization/virtualbox/7.0/user/vboxmanage.html#vboxmanage
if [[ "$("$VBOXMANAGE_CMD" list vms)" =~ $VBOX_NAME ]]; then
    echo "You have created $VBOX_NAME, just boot it in VirtualBox."
else
    echo "Creating Virtual Machine..."
    "$VBOXMANAGE_CMD" createvm --name="$VBOX_NAME" --ostype="$VBOX_OS_TYPE" --register

    # Using SSH in WSL, Linux guest VM's network should be configured to accept external request.
    # Bridge should work, while NAT with port forwarding doesn't.
    "$VBOXMANAGE_CMD" modifyvm "$VBOX_NAME" --cpus="$VBOX_CPU_NUMBER" --memory="$VBOX_MEMORY" \
        --vram="$VBOX_VRAM" --graphicscontroller=vmsvga --accelerate3d=on --nic1=nat \
        --firmware=efi --boot1=dvd --boot2=disk --boot3=none --boot4=none

    "$VBOXMANAGE_CMD" createmedium disk --filename="$ISO_DIST_DIR/$VBOX_NAME/$VBOX_NAME.${VBOX_HDD_FORMAT,,}" \
        --size="$VBOX_HDD_SIZE" --format="$VBOX_HDD_FORMAT" --variant=Fixed

    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" --name=SATA --add=sata --controller=IntelAhci

    "$VBOXMANAGE_CMD" storageattach "$VBOX_NAME" --storagectl=SATA --port=0 --device=0 --type=hdd \
        --medium="$ISO_DIST_DIR/$VBOX_NAME/$VBOX_NAME.${VBOX_HDD_FORMAT,,}"

    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" --name=IDE --add=ide --controller=PIIX4

    "$VBOXMANAGE_CMD" storageattach "$VBOX_NAME" --storagectl=IDE --port=1 --device=0 --type=dvddrive \
        --medium="$ISO_DIST_DIR/$ISO_FILE"
fi

cd "$OLDPWD"

# Start the virtual machine and the OS installation.
if [[ "$("$VBOXMANAGE_CMD" list runningvms)" =~ $VBOX_NAME ]]; then
    echo "Virtual machine $VBOX_NAME is running..."
else
    echo "Starting Virtual machine $VBOX_NAME..."
    "$VBOXMANAGE_CMD" startvm "$VBOX_NAME" --type=gui
fi

echo "Completed!" && exit 0
