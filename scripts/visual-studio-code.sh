#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if [[ -x "$(command -v code)" ]]; then
    log "Visual Studio Code is installed."
else
    log "Adding Visual Studio Code apt repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list

    log "Installing Visual Studio Code..."
    sudo apt-get update
    sudo apt-get install -y code
fi
