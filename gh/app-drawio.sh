#!/bin/bash

set -e

# draw.io Desktop - Diagramming application
# https://www.drawio.com/

if command -v drawio &>/dev/null; then
  echo "draw.io is already installed, skipping..."
  return 0
fi

echo "Installing draw.io..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
LATEST_VERSION=$(curl -sI "https://github.com/jgraph/drawio-desktop/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$LATEST_VERSION" ]; then
  echo "Failed to get latest version, using default"
  LATEST_VERSION="v24.7.17"
fi

VERSION_NUM=${LATEST_VERSION#v}

echo "Latest version: ${VERSION_NUM}"

# Download .deb package
DEB_URL="https://gh-proxy.com/https://github.com/jgraph/drawio-desktop/releases/download/${LATEST_VERSION}/drawio-amd64-${VERSION_NUM}.deb"

cd /tmp

echo "Downloading draw.io ${VERSION_NUM}..."

if wget -O drawio.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing draw.io..."
  sudo apt install -y ./drawio.deb
  rm -f drawio.deb
  echo "draw.io installation completed"
else
  echo "Error: Failed to download draw.io deb package"
  rm -f drawio.deb
  return 1
fi

cd -
