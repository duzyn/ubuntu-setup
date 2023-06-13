#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

# https://google.cn/chrome
if [[ -z "$(command -v google-chrome-stable)" ]]; then
    wget -O "$TEMP_DIR/google-chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt-get update
    sudo apt-get install -y gdebi
    sudo gdebi -n "$TEMP_DIR/google-chrome.deb"
fi

rm -rf "$TEMP_DIR"
