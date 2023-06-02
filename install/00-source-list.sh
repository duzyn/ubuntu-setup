#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"

# I can't connect to freedownloadmanager apt repo, so remove it.
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    echo "Removing Free Download Manager mirror list..."
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
fi

# Backup
if [[ ! -f /etc/apt/sources.list.origin ]]; then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.origin
fi

if [[ ! -f /etc/apt/sources.list.d/official-package-repositories.list.origin ]]; then
    sudo cp /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/official-package-repositories.list.origin
fi

# Using APT mirror.
echo "APT mirror is set to $APT_MIRROR."
sudo cp -f /etc/apt/sources.list.origin /etc/apt/sources.list
sudo cp -f /etc/apt/sources.list.d/official-package-repositories.list.origin /etc/apt/sources.list.d/official-package-repositories.list
# For Ubuntu
sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
    -e "s|http:|https:|g" /etc/apt/sources.list
# For Linux Mint
sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
    -e "s|packages.linuxmint.com|mirrors.ustc.edu.cn/linuxmint|g" -e "s|http:|https:|g" \
        /etc/apt/sources.list.d/official-package-repositories.list


echo "Updating APT..."
sudo apt-get update
