#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"

# I can't connect to freedownloadmanager apt repo, so remove it.
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    echo "Removing Free Download Manager mirror list..."
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
fi


# Using APT mirror.
echo "APT mirror is set to $APT_MIRROR."
# For Ubuntu
sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
    -e "s|http:|https:|g" /etc/apt/sources.list
# For Linux Mint
if [[ -f /etc/apt/sources.list.d/official-package-repositories.list ]]; then
sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
    -e "s|packages.linuxmint.com|mirrors.ustc.edu.cn/linuxmint|g" -e "s|http:|https:|g" \
        /etc/apt/sources.list.d/official-package-repositories.list
fi

echo "Updating APT..."
sudo apt-get update
