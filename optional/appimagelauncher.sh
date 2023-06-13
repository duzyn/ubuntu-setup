#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# https://github.com/TheAssassin/AppImageLauncher
if [[ -z "$(command -v appimagelauncher)" ]]; then
    sudo add-apt-repository -y ppa:appimagelauncher-team/stable
    sudo apt-get update
    sudo apt-get install -y appimagelauncher
fi
