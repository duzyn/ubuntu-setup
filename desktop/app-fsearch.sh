#!/bin/bash

set -e

# FSearch - Fast file search (like Everything on Windows)
# https://github.com/cboxdoerfer/fsearch

if command -v fsearch &>/dev/null; then
  echo "FSearch is already installed, skipping..."
  return 0
fi

echo "Installing FSearch..."

sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable
sudo apt update -y

if sudo apt install -y fsearch; then
  echo "FSearch installation completed"
else
  echo "Error: Failed to install FSearch"
  return 1
fi
