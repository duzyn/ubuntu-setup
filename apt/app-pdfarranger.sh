#!/bin/bash

set -e

# PDF Arranger - PDF document manipulation
# https://github.com/pdfarranger/pdfarranger

if command -v pdfarranger &>/dev/null; then
  echo "PDF Arranger is already installed, skipping..."
  return 0
fi

echo "Installing PDF Arranger..."

sudo apt update -y

if sudo apt install -y pdfarranger; then
  echo "PDF Arranger installation completed"
else
  echo "Error: Failed to install PDF Arranger"
  return 1
fi
