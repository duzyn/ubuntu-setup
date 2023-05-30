#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Albert: https://github.com/albertlauncher/albert
if [[ -n "$(command -v albert)" ]]; then
    log "Albert is installed."
else
    log "Adding Albert apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    wget -qO- "https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null

    log "Installing Albert..."
    sudo apt-get update
    sudo apt-get install -y albert
fi
