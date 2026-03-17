#!/bin/bash

set -e

# LocalSend - File sharing
# https://localsend.org/

if command -v localsend &>/dev/null; then
  echo "LocalSend is already installed, skipping..."
  return 0
fi

echo "Installing LocalSend..."

cd /tmp

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
LOCALSEND_VERSION=$(curl -sI "https://github.com/localsend/localsend/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$LOCALSEND_VERSION" ]; then
  echo "Failed to get latest version, using default"
  LOCALSEND_VERSION="1.15.0"
fi

echo "Latest version: ${LOCALSEND_VERSION}"

DEB_URL="https://gh-proxy.com/https://github.com/localsend/localsend/releases/latest/download/LocalSend-${LOCALSEND_VERSION}-linux-x86-64.deb"

echo "Downloading LocalSend ${LOCALSEND_VERSION}..."
if wget -O localsend.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing LocalSend..."
  sudo apt install -y ./localsend.deb
  rm -f localsend.deb
  echo "LocalSend installation completed"
else
  echo "Error: Failed to download LocalSend deb package"
  rm -f localsend.deb
  return 1
fi

cd -
