#!/bin/bash

set -e

# Scribus - Desktop publishing
# https://www.scribus.net/

if command -v scribus &>/dev/null; then
  echo "Scribus is already installed, skipping..."
  return 0
fi

echo "Installing Scribus..."

sudo apt update -y

if sudo apt install -y scribus; then
  echo "Scribus installation completed"
else
  echo "Error: Failed to install Scribus"
  return 1
fi
