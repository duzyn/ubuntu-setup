#!/bin/bash

set -e

# Thunderbird - Email client
# https://www.thunderbird.net/

if command -v thunderbird &>/dev/null; then
  echo "Thunderbird is already installed, skipping..."
  return 0
fi

echo "Installing Thunderbird..."

if sudo apt install -y thunderbird; then
  echo "Thunderbird installation completed"
else
  echo "Error: Failed to install Thunderbird"
  return 1
fi
