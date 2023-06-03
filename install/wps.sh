#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# https://linux.wps.cn/
WPS_INSTALLED_VERSION="not_installed"
WPS_LATEST_VERSION="$(wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb" | cut -f2 -d "_")"
if dpkg -s wps-office &>/dev/null; then
    WPS_INSTALLED_VERSION="$(dpkg -s wps-office | grep Version: | cut -f2 -d " ")"
    echo "WPS $WPS_INSTALLED_VERSION is installed."
fi

if [[ "$WPS_LATEST_VERSION" == *"$WPS_INSTALLED_VERSION"* || "$WPS_INSTALLED_VERSION" == *"$WPS_LATEST_VERSION"* ]]; then
    echo "WPS $WPS_INSTALLED_VERSION is lastest."
else
    echo "Installing WPS $WPS_LATEST_VERSION..."
    wget -O "$TMPDIR/wps-office.deb" "$(wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb")"

    sudo gdebi -n "$TMPDIR/wps-office.deb"
fi

# WPS needs to install symbol fonts.
if [[ ! -f /usr/share/fonts/wps-fonts/mtextra.ttf ]]; then
    echo "Installing WPS symbol fonts..."
    sudo mkdir -p /usr/share/fonts/wps-fonts
    sudo cp -r "wps-fonts" /usr/share/fonts
    sudo chmod 644 /usr/share/fonts/wps-fonts/*
    sudo fc-cache -vfs
fi
