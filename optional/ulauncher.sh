#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

if [[ -z "$(command -v ulauncher)" ]]; then
    sudo add-apt-repository -y ppa:agornostal/ulauncher
    sudo apt update
    sudo apt install -y ulauncher
fi