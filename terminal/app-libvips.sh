#!/bin/bash

set -e

# libvips - Image processing library
# https://www.libvips.org/

if pkg-config --exists vips; then
  echo "libvips is already installed, skipping..."
  return 0
fi

echo "Installing libvips..."

sudo apt update -y

if sudo apt install -y libvips-tools libvips-dev; then
  echo "libvips installation completed"
else
  echo "Error: Failed to install libvips"
  return 1
fi
