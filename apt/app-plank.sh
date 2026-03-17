#!/bin/bash

set -e

# Plank - Dock application
# https://github.com/ricotz/plank

if command -v plank &>/dev/null; then
  echo "Plank is already installed, skipping..."
  return 0
fi

echo "Installing Plank..."

if sudo apt install -y plank; then
  echo "Plank installation completed"
else
  echo "Error: Failed to install Plank"
  return 1
fi
