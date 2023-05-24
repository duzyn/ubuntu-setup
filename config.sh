#!/usr/bin/env bash

# Ubuntu has discontinued preseed as of 20.04 according to this:
# https://discourse.ubuntu.com/t/server-installer-plans-for-20-04-lts/13631

# VirtualBox
if [[ "$(uname -a)" =~ "WSL" ]]; then
    : "${VBOX_SETTING_DIR:="$(wslpath "$(wslvar USERPROFILE)")/.VirtualBox"}"
    : "${VBOXMANAGE_CMD:="/mnt/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"}"
    : "${VBOX_GUEST_ADDITIONS:="/mnt/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"}"
elif [[ "$(uname -a)" =~ "Linux" ]]; then
    : "${VBOXMANAGE_CMD:="/usr/bin/VBoxManage"}"
    : "${VBOX_SETTING_DIR:="$HOME/.config/VirtualBox"}"
    : "${VBOX_GUEST_ADDITIONS:="/opt/VirtualBox/additions/VBoxGuestAdditions.iso"}"
elif [[ "$(uname -a)" =~ "Darwin" ]]; then
    : "${VBOXMANAGE_CMD:="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"}"
    : "${VBOX_SETTING_DIR:="$HOME/Library/VirtualBox"}"
    : "${VBOX_GUEST_ADDITIONS:="/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"}"
fi

# Arguments given to the download router.
: "${ISO_URL:="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso"}"
: "${SOURCE_ISO="$(basename "$ISO_URL")"}"

# Virtual machine
: "${VBOX_NAME="${SOURCE_ISO%.*}"}"
: "${VBOX_OS_TYPE=Ubuntu_64}"
: "${VBOX_CPU_NUMBER=2}"
: "${VBOX_MEMORY=2048}"
: "${VBOX_VRAM=128}"
: "${VBOX_HDD_SIZE=61440}"
: "${VBOX_HDD_FORMAT=VDI}"

# Hardcoded host information.
: "${USERNAME:="xubuntu"}"
: "${PASSWORD:="xubuntu"}"
: "${FULLNAME:="xubuntu"}"
: "${HOST:="xubuntu"}"
: "${DOMAIN:="xubuntu.guest.virtualbox.org"}"
: "${LOCALE:="zh_CN"}"
: "${TIMEZONE:="Asia/Shanghai"}"
