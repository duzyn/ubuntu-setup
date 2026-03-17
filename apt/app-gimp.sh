#!/bin/bash

set -e

# GIMP - Image editor
# https://www.gimp.org/

if command -v gimp &>/dev/null; then
  echo "GIMP is already installed, skipping..."
  return 0
fi

echo "Installing GIMP..."

if sudo apt install -y gimp; then
  echo "GIMP installation completed"
else
  echo "Error: Failed to install GIMP"
  return 1
fi
