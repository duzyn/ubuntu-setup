#!/bin/bash

set -e

# CopyQ - Advanced clipboard manager
# https://hluk.github.io/CopyQ/

if command -v copyq &>/dev/null; then
  echo "CopyQ is already installed, skipping..."
  return 0
fi

echo "Installing CopyQ..."

if sudo apt install -y copyq; then
  echo "CopyQ installation completed"
else
  echo "Error: Failed to install CopyQ"
  return 1
fi
