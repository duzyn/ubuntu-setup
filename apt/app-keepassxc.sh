#!/bin/bash

set -e

# KeePassXC - Password manager
# https://keepassxc.org/

if command -v keepassxc &>/dev/null; then
  echo "KeePassXC is already installed, skipping..."
  return 0
fi

echo "Installing KeePassXC..."

if sudo apt install -y keepassxc; then
  echo "KeePassXC installation completed"
else
  echo "Error: Failed to install KeePassXC"
  return 1
fi
