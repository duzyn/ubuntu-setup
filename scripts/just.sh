#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Just: https://github.com/casey/just
if [[ -n "$(command -v just)" ]]; then
    echo "Just is installed."
else
    echo "Adding Just apt repository..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | \
        sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list

    echo "Installing Just..."
    sudo apt-get update
    sudo apt-get install -y just
fi

