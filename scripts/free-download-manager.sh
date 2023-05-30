#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Free Download Manager
log "Downloading Free Download Manager latest version..."
wget -O "$TMPDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb

[[ -d "$TMPDIR/freedownloadmanager" ]] || mkdir -p "$TMPDIR/freedownloadmanager"
ar p "$TMPDIR/freedownloadmanager.deb" control.tar.xz | tar --extract --xz --directory "$TMPDIR/freedownloadmanager"
FDM_LATEST_VERSION="$(cat "$TMPDIR/freedownloadmanager/control" | grep Version: | cut -c 10- -)"
FDM_INSTALLED_VERSION="not_installed"

if dpkg -s freedownloadmanager &>/dev/null; then
    FDM_INSTALLED_VERSION="$(dpkg -s freedownloadmanager | grep Version: | cut -c 10- -)"
    log "Free Download Manager $FDM_INSTALLED_VERSION is installed."
fi

if [[ "$FDM_LATEST_VERSION" == *"$FDM_INSTALLED_VERSION"* || "$FDM_INSTALLED_VERSION" == *"$FDM_LATEST_VERSION"* ]]; then
    log "Free Download Manager $FDM_INSTALLED_VERSION is lastest."
else
    log "Installing Free Download Manager $FDM_LATEST_VERSION..."
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
fi