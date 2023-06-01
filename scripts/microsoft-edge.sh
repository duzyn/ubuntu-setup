#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if [[ -x "$(command -v microsoft-edge-stable)" ]]; then
    echo "Microsoft Edge is installed."
else
    echo "Adding Microsoft Edge apt repository..."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | \
        sudo tee /etc/apt/sources.list.d/microsoft-edge.list

    echo "Installing Microsoft Edge..."
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
fi

