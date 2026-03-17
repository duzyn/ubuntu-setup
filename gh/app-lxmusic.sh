#!/bin/bash

set -e

# LX Music - Music player with multiple source support
# https://github.com/lyswhut/lx-music-desktop

if command -v lx-music-desktop &>/dev/null || dpkg -l lx-music-desktop &>/dev/null; then
  echo "LX Music is already installed, skipping..."
  return 0
fi

echo "Installing LX Music..."

# Fetch latest version from GitHub releases page
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/lyswhut/lx-music-desktop/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Error: Failed to fetch version"
  return 1
fi

echo "Latest version: ${VERSION}"

# Download deb package via gh-proxy
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/lyswhut/lx-music-desktop/releases/download/v${VERSION}/lx-music-desktop_${VERSION}_amd64.deb"

cd /tmp

echo "Downloading LX Music version ${VERSION}..."
if wget -O lx-music.deb "$DOWNLOAD_URL"; then
  echo "Download completed"
  echo "Installing LX Music..."
  sudo apt install -y ./lx-music.deb
  rm -f lx-music.deb
  echo "LX Music installation completed"
else
  echo "Error: Failed to download LX Music"
  rm -f lx-music.deb
  return 1
fi

cd -
