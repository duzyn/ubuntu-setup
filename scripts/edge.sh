#!/usr/bin/env bash

# https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
log "Adding Microsoft GPG keyring…"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/microsoft.gpg
sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
log "Added Microsoft GPG keyring."

if dpkg -s "microsoft-edge-stable" &> /dev/null; then
  log "Microsoft Edge browser is installed."
else
  log "Installing Microsoft Edge browser…"
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
fi
sudo apt-get update
sudo apt-get install -y microsoft-edge-stable
log "Installed Microsoft Edge browser."
