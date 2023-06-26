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

# https://google.cn/chrome
if [[ -z "$(command -v google-chrome-stable)" ]]; then
    wget -O "$TEMP_DIR/google-chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    if [[ -z "$(command -v gdebi)" ]]; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo gdebi -n "$TEMP_DIR/google-chrome.deb"
fi

rm -rf "$TEMP_DIR"
