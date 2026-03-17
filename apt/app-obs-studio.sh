#!/bin/bash

set -e

# OBS Studio - Screen recording and streaming
# https://obsproject.com/

if command -v obs &>/dev/null; then
  echo "OBS Studio is already installed, skipping..."
  return 0
fi

echo "Installing OBS Studio..."

if sudo apt install -y obs-studio; then
  echo "OBS Studio installation completed"
else
  echo "Error: Failed to install OBS Studio"
  return 1
fi
