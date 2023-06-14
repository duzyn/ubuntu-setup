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

# Greenfish Icon Editor Pro
LATEST_VESION="$(wget -qO- "http://greenfishsoftware.org/gfie.php#apage" | \
    grep -Po "Latest.+stable.+release\s\([\d.]+\)" | grep -Po "[\d.]+")"

if dpkg -s gfie &>/dev/null; then
    CURRENT_VERSION=$(dpkg -s gfie | grep ^Version: | cut -f2 -d " ")
else
    CURRENT_VERSION=noversion
fi

if [[ "$LATEST_VESION" != "$CURRENT_VERSION" ]]; then
    wget -O "$TEMP_DIR/gfie.deb" "http://greenfishsoftware.org/dl/gfie/gfie-$LATEST_VESION.deb"
    if [[ -z "$(command -v gdebi)" ]]; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo gdebi -n "$TEMP_DIR/gfie.deb"
fi

rm -rf "$TEMP_DIR"
