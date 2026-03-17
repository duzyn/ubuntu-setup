#!/bin/bash

set -e

# Clash Verge Rev - A modern GUI proxy client
# https://github.com/clash-verge-rev/clash-verge-rev

if command -v clash-verge &>/dev/null; then
  echo "Clash Verge is already installed, skipping..."
  return 0
fi

echo "Installing Clash Verge..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
LATEST_VERSION=$(curl -sI "https://github.com/clash-verge-rev/clash-verge-rev/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$LATEST_VERSION" ]; then
  echo "Failed to get latest version, using default version"
  LATEST_VERSION="v1.7.7"
fi

echo "Latest version: ${LATEST_VERSION}"

DEB_URL="https://gh-proxy.com/https://github.com/clash-verge-rev/clash-verge-rev/releases/download/${LATEST_VERSION}/clash-verge_${LATEST_VERSION#v}_amd64.deb"

cd /tmp

echo "Downloading Clash Verge ${LATEST_VERSION}..."
if wget -O clash-verge.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing Clash Verge..."
  sudo apt install -y ./clash-verge.deb
  rm -f clash-verge.deb
  echo "Clash Verge installation completed"
else
  echo "Error: Failed to download Clash Verge deb package"
  rm -f clash-verge.deb
  return 1
fi

cd -
