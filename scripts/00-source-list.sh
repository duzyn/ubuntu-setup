#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"

# I can't connect to freedownloadmanager apt repo, so remove it.
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    echo "Removing Free Download Manager mirror list..."
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
else
    echo "Free Download Manager mirror list doesn't exist."
fi

# Using APT mirror.
if [[ -f /etc/apt/sources.list ]]; then
    echo "APT mirror is set to $APT_MIRROR."
    sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
        -e "s|http:|https:|g" /etc/apt/sources.list
else
    echo "There's no sources.list." 
    exit
fi

echo "Updating APT..."
sudo apt-get update
