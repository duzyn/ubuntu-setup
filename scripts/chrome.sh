#!/usr/bin/env bash

if dpkg -s "google-chrome-stable" &> /dev/null; then
  log "Google Chrome browser is installed."
  sudo apt-get update
  sudo apt-get install -y google-chrome-stable
else
  log "Downloading Google Chrome browser…"
  wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  log "Downloaded Google Chrome browser."

  log "Installing Google Chrome…"
  sudo gdebi -n /tmp/google-chrome.deb
  log "Installed Google Chrome."
fi