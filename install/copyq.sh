#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

if [[ -z "$(command -v copyq)" ]]; then
    sudo add-apt-repository -y ppa:hluk/copyq
    sudo apt-get update
    sudo apt-get install -y copyq
fi
