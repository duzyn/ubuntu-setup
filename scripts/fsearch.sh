#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# FSearch: https://github.com/cboxdoerfer/fsearch
if [[ -n "$(command -v fsearch)" ]]; then
    log "FSearch is installed."
else
    log "Adding FSearch apt repository..."
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable

    log "Installing FSearch..."
    sudo apt-get update
    sudo apt-get install -y fsearch
fi
