#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Zim: https://zim-wiki.org/
if [[ -z "$(command -v zim)" ]]; then
    sudo add-apt-repository -y ppa:jaap.karssenberg/zim
    sudo apt-get update
    sudo apt-get install -y zim
fi
