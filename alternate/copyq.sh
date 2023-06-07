#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# CopyQ
if [[ -z "$(command -v copyq)" ]]; then
    sudo add-apt-repository -y ppa:hluk/copyq
    sudo apt update
    sudo apt install -y copyq
fi
