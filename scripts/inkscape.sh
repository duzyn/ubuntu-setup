#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Inksacpe: https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable
if [[ -n "$(command -v inkscape)" ]]; then
    log "Inksacpe is installed."
else
    log "Adding Inksacpe apt repository..."
    sudo add-apt-repository -y ppa:inkscape.dev/stable
    sudo apt-get update

    log "Installing Inksacpe..."
    sudo apt-get install -y inkscape
fi
