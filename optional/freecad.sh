#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# FreeCAD: https://launchpad.net/~freecad-maintainers/+archive/freecad-stable
if [[ -n "$(command -v freecad)" ]]; then
    echo "FreeCAD is installed."
else
    echo "Adding FreeCAD apt repository..."
    sudo add-apt-repository -y ppa:freecad-maintainers/freecad-stable
    sudo apt-get update

    echo "Installing FreeCAD..."
    sudo apt-get install -y freecad
fi
