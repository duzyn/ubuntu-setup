#!/bin/bash

set -e

# Flameshot - Screenshot tool
# https://flameshot.org/

if command -v flameshot &>/dev/null; then
  echo "Flameshot is already installed, skipping..."
  return 0
fi

echo "Installing Flameshot..."

if sudo apt install -y flameshot; then
  echo "Flameshot installation completed"
else
  echo "Error: Failed to install Flameshot"
  return 1
fi
