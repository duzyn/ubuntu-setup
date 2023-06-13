#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

# https://code.visualstudio.com/docs/setup/linux
if [[ -z "$(command -v code)" ]]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
fi

rm -rf "$TEMP_DIR"