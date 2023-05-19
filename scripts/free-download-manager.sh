#!/usr/bin/env bash

## Free Download Manager
if dpkg -s "freedownloadmanager" &> /dev/null; then
  log "Free Download Manager is installed."
  sudo apt-get update
  sudo apt-get install -y freedownloadmanager
else
  log "Downloading Free Download Manager…"
  wget -O /tmp/freedownloadmanager.deb https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb
  log "Downloaded Free Download Manager."

  log "Installing Free Download Manager…"
  sudo gdebi -n /tmp/freedownloadmanager.deb
  log "Installed Free Download Manager."
fi
