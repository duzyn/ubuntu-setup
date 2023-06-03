#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${UBUNTU_CODENAME:="focal"}"

# https://docs.makedeb.org/prebuilt-mpr/getting-started/
if [[ -e "/etc/apt/sources.list.d/prebuilt-mpr.list" ]]; then
    echo "Prebuilt-MPR apt repository is added."
else
    echo "Adding Prebuilt-MPR apt repository..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $UBUNTU_CODENAME" | \
        sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
    sudo apt-get update
fi

sudo apt-get install -y \
    bat \
    fd \
    just \
    ripgrep


