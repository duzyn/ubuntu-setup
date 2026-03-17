#!/bin/bash

set -e

# DBeaver - Database management tool
# https://dbeaver.io/

if command -v dbeaver &>/dev/null || command -v dbeaver-ce &>/dev/null; then
  echo "DBeaver is already installed, skipping..."
  return 0
fi

echo "Installing DBeaver..."

cd /tmp

# Fetch latest version from GitHub releases page (scrape webpage to avoid API rate limits)
echo "Fetching latest version..."
LATEST_VERSION=$(curl -sI "https://github.com/dbeaver/dbeaver/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$LATEST_VERSION" ]; then
  echo "Failed to get latest version, using default version"
  LATEST_VERSION="v24.3.0"
fi

VERSION_NUM=${LATEST_VERSION#v}

echo "Latest version: ${VERSION_NUM}"

echo "Downloading DBeaver ${VERSION_NUM}..."

DEB_URL="https://gh-proxy.com/https://github.com/dbeaver/dbeaver/releases/download/${LATEST_VERSION}/dbeaver-ce_${VERSION_NUM}_amd64.deb"

if wget -O dbeaver.deb "$DEB_URL"; then
  echo "Download completed"
  echo "Installing DBeaver..."
  sudo apt install -y ./dbeaver.deb
  rm -f dbeaver.deb
  echo "DBeaver installation completed"
else
  echo "Error: Failed to download DBeaver deb package"
  rm -f dbeaver.deb
  return 1
fi

cd -
