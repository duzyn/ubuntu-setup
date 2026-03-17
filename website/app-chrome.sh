#!/bin/bash

set -e

# Google Chrome - Web browser
# https://www.google.com/chrome/

DOWNLOAD_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
TEMP_FILE="/tmp/google-chrome.deb"

if command -v google-chrome-stable &>/dev/null; then
  echo "Google Chrome is already installed, skipping..."
  return 0
fi

echo "Downloading Google Chrome..."

if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
  echo "Error: Failed to download Google Chrome"
  rm -f "$TEMP_FILE"
  return 1
fi

echo "Download completed"
echo "Installing Google Chrome..."

if ! sudo apt install -y "$TEMP_FILE"; then
  echo "Error: Failed to install Google Chrome"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
echo "Google Chrome installation completed"
