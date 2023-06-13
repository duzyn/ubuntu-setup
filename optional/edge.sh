#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

### Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if [[ -z "$(command -v microsoft-edge-stable)" ]]; then
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | \
        sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
fi

rm -rf "$TEMP_DIR"
