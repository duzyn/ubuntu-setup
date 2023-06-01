#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Onedriver: https://github.com/jstaf/onedriver
if [[ -n "$(command -v onedriver)" ]]; then
    echo "Onedriver is installed."
else
    echo "Adding Onedriver apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null

    echo "Installing Onedriver..."
    sudo apt-get update
    sudo apt-get install -y onedriver
fi