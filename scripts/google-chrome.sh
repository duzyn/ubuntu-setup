#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Google Chrome: https://google.cn/chrome
if [[ -x "$(command -v google-chrome-stable)" ]]; then
    log "Google Chrome is installed."
else
    log "Downloading Google Chrome..."
    wget -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

    log "Installing Google Chrome..."
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
fi

