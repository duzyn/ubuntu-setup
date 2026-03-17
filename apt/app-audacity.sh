#!/bin/bash

set -e

# Audacity - Audio editor
# https://www.audacityteam.org/

if command -v audacity &>/dev/null; then
  echo "Audacity is already installed, skipping..."
  return 0
fi

echo "Installing Audacity..."

if sudo apt install -y audacity; then
  echo "Audacity installation completed"
else
  echo "Error: Failed to install Audacity"
  return 1
fi
