#!/bin/bash

set -e

# Joplin - Note taking application
# https://joplinapp.org/
# https://github.com/laurent22/joplin

if command -v joplin &>/dev/null || [ -f "$HOME/.local/share/applications/joplin.desktop" ]; then
  echo "Joplin is already installed, skipping..."
  return 0
fi

echo "Installing Joplin..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/laurent22/joplin/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Failed to get latest version, using default"
  VERSION="3.5.13"
fi

echo "Latest version: ${VERSION}"

# Download deb package via gh-proxy
DEB_URL="https://gh-proxy.com/https://github.com/laurent22/joplin/releases/download/v${VERSION}/Joplin-${VERSION}.deb"

cd /tmp

echo "Downloading Joplin ${VERSION}..."
if wget -O joplin.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing Joplin..."
  sudo apt install -y ./joplin.deb
  rm -f joplin.deb
  echo "Joplin installation completed"
else
  echo "Error: Failed to download Joplin deb package"
  rm -f joplin.deb
  return 1
fi

cd -
