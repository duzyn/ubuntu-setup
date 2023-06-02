#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Git latest version
if [[ -x "$(command -v git)" ]]; then
    echo "Git is installed."
else
    echo "Adding Git apt repository..."
    sudo add-apt-repository -y ppa:git-core/ppa
    
    echo "Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

