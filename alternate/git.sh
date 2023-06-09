#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Git latest version
if [[ -z "$(command -v git)" ]]; then
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get install -y git
fi

