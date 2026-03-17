#!/bin/bash

set -e

# Free Download Manager - Download accelerator
# https://www.freedownloadmanager.org/

DOWNLOAD_URL="https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb"
TEMP_FILE="/tmp/freedownloadmanager.deb"

if command -v fdm &>/dev/null || [ -f "/opt/freedownloadmanager/fdm" ]; then
  echo "Free Download Manager is already installed, skipping..."
  return 0
fi

echo "Installing Free Download Manager..."
echo "Fetching latest version..."

VERSION=$(curl -sL "https://www.freedownloadmanager.org/download-fdm-for-linux.htm" | grep -oP 'FDM \K[\d.]+' | head -1)

if [[ -n "$VERSION" ]]; then
  echo "Latest version: ${VERSION}"
fi

echo "Downloading Free Download Manager..."

if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
  echo "Error: Failed to download Free Download Manager"
  rm -f "$TEMP_FILE"
  return 1
fi

echo "Download completed"
echo "Installing Free Download Manager..."

if ! sudo apt install -y "$TEMP_FILE"; then
  echo "Error: Failed to install Free Download Manager"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
echo "Free Download Manager installation completed"
