#!/bin/bash

set -e

# Ulauncher - Application launcher
# https://ulauncher.io/
# https://github.com/Ulauncher/Ulauncher

if command -v ulauncher &>/dev/null; then
  echo "Ulauncher is already installed, skipping..."
  return 0
fi

echo "Installing Ulauncher..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/Ulauncher/Ulauncher/releases/latest" | grep -i "location:" | grep -oP 'tag/\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Failed to get latest version, using default"
  VERSION="5.15.15"
fi

echo "Latest version: ${VERSION}"

# Download deb package via gh-proxy
DEB_URL="https://gh-proxy.com/https://github.com/Ulauncher/Ulauncher/releases/download/${VERSION}/ulauncher_${VERSION}_all.deb"

cd /tmp

echo "Downloading Ulauncher ${VERSION}..."
if wget -O ulauncher.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing Ulauncher..."
  sudo apt install -y ./ulauncher.deb
  rm -f ulauncher.deb
  echo "Ulauncher installation completed"
else
  echo "Error: Failed to download Ulauncher deb package"
  rm -f ulauncher.deb
  return 1
fi

cd -
