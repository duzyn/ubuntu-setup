#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Google Chrome: https://google.cn/chrome
if [[ -n "$(command -v google-chrome-stable)" ]]; then
    echo "Google Chrome is installed."
else
    echo "Downloading Google Chrome..."
    wget --show-progress -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    echo "Installing Google Chrome..."
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
fi

