#!/bin/bash

set -e

# Inkscape - Vector graphics editor
# https://inkscape.org/

if command -v inkscape &>/dev/null; then
  echo "Inkscape is already installed, skipping..."
  return 0
fi

echo "Installing Inkscape..."

if sudo apt install -y inkscape; then
  echo "Inkscape installation completed"
else
  echo "Error: Failed to install Inkscape"
  return 1
fi
