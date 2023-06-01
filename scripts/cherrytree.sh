#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# CherryTree: https://www.giuspen.net/cherrytree/
if [[ -n "$(command -v cherrytree)" ]]; then
    echo "CherryTree is installed."
else
    echo "Adding CherryTree apt repository..."
    sudo add-apt-repository -y ppa:giuspen/ppa
    sudo apt-get update

    echo "Installing CherryTree..."
    sudo apt-get install -y cherrytree
fi
