#!/bin/bash

set -e

# Install essential fonts for development and Chinese support

echo "Installing fonts..."

sudo apt update -y

# Noto CJK fonts (Chinese support)
echo "Installing Noto CJK fonts..."
if ! sudo apt install -y fonts-noto-cjk; then
  echo "Error: Failed to install Noto CJK fonts"
  return 1
fi

# Fira Code (programming font with ligatures)
echo "Installing Fira Code..."
if ! sudo apt install -y fonts-firacode; then
  echo "Error: Failed to install Fira Code"
  return 1
fi
