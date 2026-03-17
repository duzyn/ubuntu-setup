#!/bin/bash

set -e

# Pandoc - Document conversion
# https://pandoc.org/

if command -v pandoc &>/dev/null; then
  echo "Pandoc is already installed, skipping..."
  return 0
fi

echo "Installing Pandoc..."

sudo apt update -y

if sudo apt install -y pandoc; then
  echo "Pandoc installation completed"
else
  echo "Error: Failed to install Pandoc"
  return 1
fi
