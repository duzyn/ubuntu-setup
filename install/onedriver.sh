#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${UBUNTU_VERSION:="22.04"}"

# Onedriver: https://github.com/jstaf/onedriver
if [[ ! -f /etc/apt/sources.list.d/home:jstaf.list ]]; then
    echo "Adding Onedriver apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$UBUNTU_VERSION/ /" | \
        sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget --show-progress -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$UBUNTU_VERSION/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
fi

sudo apt-get install -y onedriver
