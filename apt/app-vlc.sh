#!/bin/bash

set -e

# VLC - Media player
# https://www.videolan.org/vlc/

if command -v vlc &>/dev/null; then
  echo "VLC is already installed, skipping..."
  return 0
fi

echo "Installing VLC..."

if sudo apt install -y vlc; then
  echo "VLC installation completed"
else
  echo "Error: Failed to install VLC"
  return 1
fi
