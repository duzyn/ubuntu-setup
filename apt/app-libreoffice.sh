#!/bin/bash

set -e

# LibreOffice - Office suite
# https://www.libreoffice.org/

if command -v libreoffice &>/dev/null; then
  echo "LibreOffice is already installed, skipping..."
  return 0
fi

echo "Installing LibreOffice..."

if sudo apt install -y libreoffice; then
  echo "LibreOffice installation completed"
else
  echo "Error: Failed to install LibreOffice"
  return 1
fi
