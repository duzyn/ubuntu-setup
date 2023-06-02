#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Free Download Manager
# Get latest version from deb file
# echo "Downloading Free Download Manager latest version..."
# wget --show-progress -O "$TMPDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
# mkdir -p "$TMPDIR/freedownloadmanager"
# ar p "$TMPDIR/freedownloadmanager.deb" control.tar.xz | tar --extract --xz --directory "$TMPDIR/freedownloadmanager"
# FDM_LATEST_VERSION="$(cat "$TMPDIR/freedownloadmanager/control" | grep Version: | cut -f2 -d " ")"

FDM_INSTALLED_VERSION="not_installed"
FDM_LATEST_VERSION="$(wget --show-progress -qO- "https://www.freedownloadmanager.org/board/viewtopic.php?f=1&t=17900" | \
    grep -Po "([\d.]+)\s*\[\w+.*?STABLE" | head -n 1 | cut -f1 -d " ")"
if dpkg -s freedownloadmanager &>/dev/null; then
    FDM_INSTALLED_VERSION="$(dpkg -s freedownloadmanager | grep Version: | cut -f2 -d " ")"
    echo "Free Download Manager $FDM_INSTALLED_VERSION is installed."
fi

if [[ "$FDM_LATEST_VERSION" == *"$FDM_INSTALLED_VERSION"* || "$FDM_INSTALLED_VERSION" == *"$FDM_LATEST_VERSION"* ]]; then
    echo "Free Download Manager $FDM_INSTALLED_VERSION is lastest."
else
    echo "Installing Free Download Manager $FDM_LATEST_VERSION..."
    wget --show-progress -O "$TMPDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
fi