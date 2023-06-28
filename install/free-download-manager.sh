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

LATEST_VERSION=$(wget -qO- "https://www.freedownloadmanager.org/board/viewtopic.php?f=1&t=17900" | \
    grep -Po "([\d.]+)\s*\[\w+.*?STABLE" | head -n 1 | cut -f1 -d " ")

if dpkg -s freedownloadmanager &>/dev/null; then
    CURRENT_VERSION=$(dpkg -s freedownloadmanager | grep ^Version: | cut -f2 -d " ")
else
    CURRENT_VERSION=noversion
fi

if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    wget -O "$TEMP_DIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb

    if [[ -z "$(command -v gdebi)" ]]; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo gdebi -n "$TEMP_DIR/freedownloadmanager.deb"
fi

# repo 在国内连不上，所以直接删掉。通过上述方法从官网安装更新
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
fi

rm -rf "$TEMP_DIR"
