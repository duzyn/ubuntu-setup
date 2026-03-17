#!/bin/bash

set -e

# MuPDF - PDF tools
# https://mupdf.com/

if command -v mutool &>/dev/null; then
  echo "MuPDF is already installed, skipping..."
  return 0
fi

echo "Installing MuPDF..."

sudo apt update -y

if sudo apt install -y mupdf-tools; then
  echo "MuPDF installation completed"
else
  echo "Error: Failed to install MuPDF"
  return 1
fi
