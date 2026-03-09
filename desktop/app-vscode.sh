#!/bin/bash

set -e

# Based on official instructions: https://code.visualstudio.com/docs/setup/linux

if command -v code &>/dev/null; then
  exit 0
fi

sudo apt install -y wget git apt-transport-https


cd /tmp
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
rm -f microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

sudo apt update
sudo apt install -y code
cd -
