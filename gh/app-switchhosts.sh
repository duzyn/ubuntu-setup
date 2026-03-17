#!/bin/bash

set -e

# SwitchHosts - Hosts file management
# https://github.com/oldj/SwitchHosts

if command -v SwitchHosts &>/dev/null || [ -f "$HOME/.local/share/applications/switchhosts.desktop" ]; then
  echo "SwitchHosts is already installed, skipping..."
  return 0
fi

echo "Installing SwitchHosts..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/oldj/SwitchHosts/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Failed to get latest version, using default"
  VERSION="4.2.0"
fi

echo "Latest version: ${VERSION}"

BUILD_NUMBER="6119"
DEB_URL="https://gh-proxy.com/https://github.com/oldj/SwitchHosts/releases/download/v${VERSION}/SwitchHosts_linux_amd64_${VERSION}.${BUILD_NUMBER}.deb"

cd /tmp

echo "Downloading SwitchHosts ${VERSION}..."
if wget -O switchhosts.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing SwitchHosts..."
  sudo apt install -y ./switchhosts.deb
  rm -f switchhosts.deb
  echo "SwitchHosts installation completed"
else
  echo "Error: Failed to download SwitchHosts deb package"
  rm -f switchhosts.deb
  return 1
fi

cd -
