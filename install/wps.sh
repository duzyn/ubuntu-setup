#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

# Remove LibreOffice, use WPS Office instead.
sudo apt purge --auto-remove -y libreoffice*

# https://linux.wps.cn/
LATEST_VERSION=$(wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb" | cut -f2 -d "_")

if dpkg -s wps-office &>/dev/null; then
    CURRENT_VERSION=$(dpkg -s wps-office | grep ^Version: | cut -f2 -d " ")
else
    CURRENT_VERSION=noversion
fi

if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb" | xargs wget -O "$TEMP_DIR/wps-office.deb"
    if [[ -z "$(command -v gdebi)" ]]; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo gdebi -n "$TEMP_DIR/wps-office.deb"
fi

# WPS needs to install symbol fonts.
if [[ ! -d /usr/share/fonts/wps-fonts ]]; then
    [[ -f /usr/share/fonts/wps-fonts/mtextra.ttf ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/mtextra.ttf
    [[ -f /usr/share/fonts/wps-fonts/symbol.ttf ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/symbol.ttf
    [[ -f /usr/share/fonts/wps-fonts/WEBDINGS.TTF ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WEBDINGS.TTF
    [[ -f /usr/share/fonts/wps-fonts/symbol.ttf ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/wingding.ttf
    [[ -f /usr/share/fonts/wps-fonts/wingding.ttf ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WINGDNG2.ttf
    [[ -f /usr/share/fonts/wps-fonts/WINGDNG2.ttf ]] ||
        wget -P "$TEMP_DIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WINGDNG3.ttf
    sudo cp -rf "$TEMP_DIR/wps-fonts" /usr/share/fonts
    sudo chmod 644 /usr/share/fonts/wps-fonts/*
    sudo fc-cache -fs
fi

rm -rf "$TEMP_DIR"
