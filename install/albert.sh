#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${UBUNTU_VERSION:="20.04"}"

# Albert: https://github.com/albertlauncher/albert
if [[ ! -f /etc/apt/sources.list.d/home:manuelschneid3r.list ]]; then
    echo "Adding Albert apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$UBUNTU_VERSION/ /" | \
        sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    wget -qO- "https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$UBUNTU_VERSION/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
    sudo apt-get update
fi

sudo apt-get install -y albert
