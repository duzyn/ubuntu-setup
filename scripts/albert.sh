#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Albert: https://github.com/albertlauncher/albert
if [[ -n "$(command -v albert)" ]]; then
    echo "Albert is installed."
else
    echo "Adding Albert apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    wget -qO- "https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
    sudo apt-get update

    echo "Installing Albert..."
    sudo apt-get install -y albert
fi
