#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# FreeCAD: https://launchpad.net/~freecad-maintainers/+archive/freecad-stable
if [[ -n "$(command -v freecad)" ]]; then
    log "FreeCAD is installed."
else
    log "Adding FreeCAD apt repository..."
    sudo add-apt-repository -y ppa:freecad-maintainers/freecad-stable
    sudo apt-get update

    log "Installing FreeCAD..."
    sudo apt-get install -y freecad
fi
