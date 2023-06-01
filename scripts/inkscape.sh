#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Inksacpe: https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable
if [[ -n "$(command -v inkscape)" ]]; then
    echo "Inksacpe is installed."
else
    echo "Adding Inksacpe apt repository..."
    sudo add-apt-repository -y ppa:inkscape.dev/stable
    sudo apt-get update

    echo "Installing Inksacpe..."
    sudo apt-get install -y inkscape
fi
