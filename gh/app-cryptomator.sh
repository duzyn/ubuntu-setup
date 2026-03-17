#!/bin/bash

set -e

# Cryptomator - File encryption
# https://cryptomator.org/
# https://github.com/cryptomator/cryptomator

if command -v cryptomator &>/dev/null; then
  echo "Cryptomator is already installed, skipping..."
  return 0
fi

echo "Installing Cryptomator..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/cryptomator/cryptomator/releases/latest" | grep -i "location:" | grep -oP 'tag/\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Failed to get latest version, using default"
  VERSION="1.19.1"
fi

echo "Latest version: ${VERSION}"

# Download deb package via gh-proxy
DEB_URL="https://gh-proxy.com/https://github.com/cryptomator/cryptomator/releases/download/${VERSION}/cryptomator_${VERSION}-0ppa1_amd64.deb"

cd /tmp

echo "Downloading Cryptomator ${VERSION}..."
if wget -O cryptomator.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing Cryptomator..."
  sudo apt install -y ./cryptomator.deb
  rm -f cryptomator.deb
  echo "Cryptomator installation completed"
else
  echo "Error: Failed to download Cryptomator deb package"
  rm -f cryptomator.deb
  return 1
fi

cd -
