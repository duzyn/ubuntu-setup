#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${UBUNTU_CODENAME:="focal"}"

# https://docs.makedeb.org/installing/apt-repository/
if [[ -e "/etc/apt/sources.list.d/makedeb.list" ]]; then
    echo "MPR apt repository is added."
else
    echo "Adding MPR apt repository..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg 1> /dev/null
    echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | \
        sudo tee /etc/apt/sources.list.d/makedeb.list
    sudo apt update
fi

sudo apt-get install -y makedeb mist


