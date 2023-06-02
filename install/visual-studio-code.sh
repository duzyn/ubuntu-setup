#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    echo "Adding Visual Studio Code apt repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
fi

sudo apt-get install -y code
