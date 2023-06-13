#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable
if [[ -z "$(command -v inkscape)" ]]; then
    sudo add-apt-repository -y ppa:inkscape.dev/stable
    sudo apt-get update
    sudo apt-get install -y inkscape
fi
