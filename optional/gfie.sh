#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

# Greenfish Icon Editor Pro
LATEST_VESION="$(wget -qO- "http://greenfishsoftware.org/gfie.php#apage" | \
    grep -Po "Latest.+stable.+release\s\([\d.]+\)" | grep -Po "[\d.]+")"
CURRENT_VERSION=noversion
CURRENT_VERSION=$(dpkg -s gfie &>/dev/null && dpkg -s gfie | grep Version: | cut -f2 -d " ")

if [[ "$LATEST_VESION" != "$CURRENT_VERSION" ]]; then
    wget -O "$TEMP_DIR/gfie.deb" "http://greenfishsoftware.org/dl/gfie/gfie-$GFIE_LATEST_VESION.deb"
    sudo apt-get update
    sudo apt-get install -y gdebi
    sudo gdebi -n "$TEMP_DIR/gfie.deb"
fi

rm -rf "$TEMP_DIR"
