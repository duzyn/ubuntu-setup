#!/bin/bash

set -e

# Visual Studio Code - Code editor
# https://code.visualstudio.com/

APP_NAME="code"
DOWNLOAD_URL="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
TEMP_FILE="/tmp/vscode.deb"

if command -v "$APP_NAME" &>/dev/null; then
  echo "Visual Studio Code is already installed, skipping..."
  return 0
fi

echo "Fetching latest version..."

VERSION=$(curl -sIL "$DOWNLOAD_URL" | grep -i "location:" | grep -oP 'code[_-][\d.]+[_-]' | grep -oP '[\d.]+' | head -1)

if [[ -n "$VERSION" ]]; then
  echo "Latest version: ${VERSION}"
fi

echo "Downloading Visual Studio Code..."

if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
  echo "Error: Failed to download Visual Studio Code"
  rm -f "$TEMP_FILE"
  return 1
fi

echo "Download completed"
echo "Installing Visual Studio Code..."

if ! sudo apt install -y "$TEMP_FILE"; then
  echo "Error: Failed to install Visual Studio Code"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
echo "Visual Studio Code installation completed"
