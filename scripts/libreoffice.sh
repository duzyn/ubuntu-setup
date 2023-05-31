#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# LibreOffice: https://launchpad.net/~libreoffice/+archive/ubuntu/ppa
if [[ -n "$(command -v libreoffice-writer)" ]]; then
    log "LibreOffice is installed."
else
    log "Adding LibreOffice apt repository..."
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt-get update

    log "Installing LibreOffice..."
    sudo apt-get install -y libreoffice libreoffice-help-zh-cn libreoffice-l10n-zh-cn
fi
