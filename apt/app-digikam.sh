#!/bin/bash

set -e

# digiKam - Professional photo management
# https://www.digikam.org/

if command -v digikam &>/dev/null; then
  echo "digiKam is already installed, skipping..."
  return 0
fi

echo "Installing digiKam..."

sudo apt update -y

if sudo apt install -y digikam; then
  echo "digiKam installation completed"
else
  echo "Error: Failed to install digiKam"
  return 1
fi
