#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Git latest version
if [[ -x "$(command -v git)" ]]; then
    log "Git is installed."
else
    log "Adding Git apt repository..."
    sudo add-apt-repository -y ppa:git-core/ppa
    
    log "Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

