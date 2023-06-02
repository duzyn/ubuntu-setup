#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Zim: https://zim-wiki.org/
if [[ -n "$(command -v zim)" ]]; then
    echo "Zim is installed."
else
    echo "Adding Zim apt repository..."
    sudo add-apt-repository -y ppa:jaap.karssenberg/zim
    sudo apt-get update

    echo "Installing Zim..."
    sudo apt-get install -y zim
fi
