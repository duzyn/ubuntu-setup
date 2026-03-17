#!/bin/bash

set -e

# WPS Office - Office suite
# https://linux.wps.cn/

TEMP_FILE="/tmp/wps-office.deb"

if command -v wps &>/dev/null; then
  echo "WPS Office is already installed, skipping..."
  return 0
fi

echo "Installing WPS Office..."
echo "Fetching latest version..."

VERSION=$(curl -sL "https://linux.wps.cn/" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)

if [[ -z "$VERSION" ]]; then
  VERSION="12.1.2.24730"
  echo "Warning: Could not fetch latest version, using fallback: ${VERSION}"
else
  echo "Latest version: ${VERSION}"
fi

BUILD_NUMBER=$(echo "$VERSION" | grep -oP '\d+$')

DOWNLOAD_URL="https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/${BUILD_NUMBER}/wps-office_${VERSION}.XA_amd64.deb"

echo "Downloading WPS Office version ${VERSION}..."

if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
  echo "Error: Failed to download WPS Office"
  rm -f "$TEMP_FILE"
  return 1
fi

echo "Download completed"
echo "Installing WPS Office..."

if ! sudo apt install -y "$TEMP_FILE"; then
  echo "Error: Failed to install WPS Office"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
echo "WPS Office installation completed"
