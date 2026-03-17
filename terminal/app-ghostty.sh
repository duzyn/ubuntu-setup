#!/bin/bash

set -e

# Ghostty - Terminal emulator
# https://github.com/ghostty-org/ghostty

if command -v ghostty &>/dev/null; then
  echo "Ghostty is already installed, skipping..."
  return 0
fi

echo "Installing Ghostty..."

cd /tmp

GHOSTTY_URL="https://gh-proxy.com/https://github.com/ghostty-org/ghostty/releases/latest/download/ghostty-ubuntu-x86_64.deb"

echo "Downloading Ghostty..."
if wget -O ghostty.deb "$GHOSTTY_URL"; then
  echo "Download completed"
  echo "Installing Ghostty..."
  sudo apt install -y ./ghostty.deb
  rm -f ghostty.deb
  echo "Ghostty installation completed"
else
  echo "Error: Failed to download Ghostty deb package"
  echo "Note: Ghostty may not have a deb package for all versions"
  rm -f ghostty.deb
  return 1
fi

cd -
