#!/bin/bash

set -e

# Calibre - E-book management
# https://calibre-ebook.com/

if command -v calibre &>/dev/null; then
  echo "Calibre is already installed, skipping..."
  return 0
fi

echo "Installing Calibre..."

if sudo apt install -y calibre; then
  echo "Calibre installation completed"
else
  echo "Error: Failed to install Calibre"
  return 1
fi
