#!/usr/bin/env bash

# https://code.visualstudio.com/docs/setup/linux
if dpkg -s "code" &> /dev/null; then
  log "Visual Studio Code is installed."
else
  log "Installing Visual Studio Code…"
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
fi
sudo apt-get update
sudo apt-get install -y code
log "Installed Visual Studio Code."