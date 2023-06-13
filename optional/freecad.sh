#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# https://launchpad.net/~freecad-maintainers/+archive/freecad-stable
if [[ -z "$(command -v freecad)" ]]; then
    sudo add-apt-repository -y ppa:freecad-maintainers/freecad-stable
    sudo apt-get update
    sudo apt-get install -y freecad
fi
