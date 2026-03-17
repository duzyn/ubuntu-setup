#!/bin/bash

set -e

# HandBrake - Video transcoder
# https://handbrake.fr/

if command -v handbrake &>/dev/null || command -v ghb &>/dev/null; then
  echo "HandBrake is already installed, skipping..."
  return 0
fi

echo "Installing HandBrake..."

if sudo apt install -y handbrake; then
  echo "HandBrake installation completed"
else
  echo "Error: Failed to install HandBrake"
  return 1
fi
