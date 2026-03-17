#!/bin/bash

set -e

# Fastfetch - System information display
# https://github.com/fastfetch-cli/fastfetch

if command -v fastfetch &>/dev/null; then
  echo "Fastfetch is already installed, skipping..."
  return 0
fi

echo "Installing Fastfetch..."

sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
sudo apt update -y

if sudo apt install -y fastfetch; then
  echo "Fastfetch installation completed"
else
  echo "Error: Failed to install Fastfetch"
  return 1
fi
