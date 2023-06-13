#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# https://github.com/cboxdoerfer/fsearch
if [[ -z "$(command -v fsearch)" ]]; then
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
fi

