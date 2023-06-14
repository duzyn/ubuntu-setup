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

if [[ -z "$(command -v gdebi)" ]]; then
    sudo apt-get update
    sudo apt-get install -y gdebi
fi

if ! dpkg -s ukylin-wine &>/dev/null; then
    wget -O "$TEMP_DIR/ukylin-wine.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n "$TEMP_DIR/ukylin-wine.deb"
fi

if ! dpkg -s ukylin-wxwork &>/dev/null; then
    wget -O "$TEMP_DIR/ukylin-wxwork.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
    sudo gdebi -n "$TEMP_DIR/ukylin-wxwork.deb"
fi

rm -rf "$TEMP_DIR"
