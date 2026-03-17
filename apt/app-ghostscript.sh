#!/bin/bash

set -e

# Ghostscript - PostScript and PDF processing
# https://www.ghostscript.com/

if command -v gs &>/dev/null; then
  echo "Ghostscript is already installed, skipping..."
  return 0
fi

echo "Installing Ghostscript..."

sudo apt update -y

if sudo apt install -y ghostscript; then
  echo "Ghostscript installation completed"
else
  echo "Error: Failed to install Ghostscript"
  return 1
fi
