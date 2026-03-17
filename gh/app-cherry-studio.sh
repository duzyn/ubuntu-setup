#!/bin/bash

set -e

# Cherry Studio - AI client for multiple LLM providers
# https://github.com/CherryHQ/cherry-studio

if command -v cherry-studio &>/dev/null || dpkg -l cherry-studio &>/dev/null; then
  echo "Cherry Studio is already installed, skipping..."
  return 0
fi

echo "Installing Cherry Studio..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://gh-proxy.com/https://github.com/CherryHQ/cherry-studio/releases/latest" | grep -i "location:" | grep -oP 'tag/\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Error: Failed to fetch version"
  return 1
fi

VERSION_NUM=${VERSION#v}
echo "Latest version: ${VERSION_NUM}"

# Download deb package via gh-proxy
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/CherryHQ/cherry-studio/releases/download/${VERSION}/Cherry-Studio-${VERSION_NUM}_amd64.deb"

cd /tmp

echo "Downloading Cherry Studio version ${VERSION_NUM}..."
if wget -O cherry-studio.deb "$DOWNLOAD_URL"; then
  echo "Download completed"
  echo "Installing Cherry Studio..."
  sudo apt install -y ./cherry-studio.deb
  rm -f cherry-studio.deb
  echo "Cherry Studio installation completed"
else
  echo "Error: Failed to download Cherry Studio"
  rm -f cherry-studio.deb
  return 1
fi

cd -
