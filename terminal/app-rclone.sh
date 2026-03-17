#!/bin/bash

set -e

# rclone - Cloud storage sync
# https://rclone.org/
# https://github.com/rclone/rclone

if command -v rclone &>/dev/null; then
  echo "rclone is already installed, skipping..."
  return 0
fi

echo "Installing rclone..."

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/rclone/rclone/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Error: Failed to fetch version"
  return 1
fi

echo "Latest version: ${VERSION}"

# Download deb package via gh-proxy
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/rclone/rclone/releases/download/v${VERSION}/rclone-v${VERSION}-linux-amd64.deb"

cd /tmp

echo "Downloading rclone version ${VERSION}..."
if wget -O rclone.deb "$DOWNLOAD_URL"; then
  echo "Download completed"
  echo "Installing rclone..."
  sudo apt install -y ./rclone.deb
  rm -f rclone.deb
  echo "rclone installation completed"
else
  echo "Error: Failed to download rclone"
  rm -f rclone.deb
  return 1
fi

cd -
