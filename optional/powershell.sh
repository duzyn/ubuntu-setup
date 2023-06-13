#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

if [[ -z "$(command -v pwsh)" ]]; then
    wget -O "$TEMP_DIR/packages-microsoft-prod.deb" "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    sudo dpkg -i "$TEMP_DIR/packages-microsoft-prod.deb"
    sudo apt-get update
    sudo apt-get install -y powershell
fi

rm -rf "$TEMP_DIR"
