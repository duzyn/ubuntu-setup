#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

LATEST_VERSION=$(wget -qO- "https://www.freedownloadmanager.org/board/viewtopic.php?f=1&t=17900" | \
    grep -Po "([\d.]+)\s*\[\w+.*?STABLE" | head -n 1 | cut -f1 -d " ")
CURRENT_VERSION=noversion
CURRENT_VERSION=$(dpkg -s freedownloadmanager &>/dev/null && dpkg -s freedownloadmanager | grep Version: | cut -f2 -d " ")

if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    wget -O "$TEMP_DIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo apt-get update
    sudo apt-get install -y gdebi
    sudo gdebi -n "$TEMP_DIR/freedownloadmanager.deb"
fi

# repo 在国内连不上，所以直接删掉。通过上述方法从官网安装更新
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
fi

rm -rf "$TEMP_DIR"
