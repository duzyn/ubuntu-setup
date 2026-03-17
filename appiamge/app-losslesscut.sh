#!/bin/bash

set -e

# LosslessCut - Video trimming tool
# https://github.com/mifi/lossless-cut

APP_NAME="LosslessCut"
APPIMAGE_NAME="LosslessCut"
DESKTOP_FILE="$HOME/.local/share/applications/losslesscut.desktop"

if [ -f "$DESKTOP_FILE" ] || command -v losslesscut &>/dev/null; then
  echo "$APP_NAME is already installed, skipping..."
  return 0
fi

echo "Installing $APP_NAME..."

# Ensure Gear Lever is installed first
echo "Checking for Gear Lever..."
if ! flatpak list | grep -q "it.mijorus.gearlever"; then
  echo "Installing Gear Lever via Flatpak..."
  flatpak install -y flathub it.mijorus.gearlever
fi

# Fetch latest version from GitHub releases page
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/mifi/lossless-cut/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [ -z "$VERSION" ]; then
  echo "Error: Failed to fetch version"
  return 1
fi

echo "Latest version: ${VERSION}"

# Download AppImage via gh-proxy
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/mifi/lossless-cut/releases/download/v${VERSION}/LosslessCut-linux-x64.AppImage"

APPIMAGE_DIR="$HOME/Applications"
mkdir -p "$APPIMAGE_DIR"

cd /tmp

echo "Downloading $APP_NAME version ${VERSION}..."
if wget -O LosslessCut.AppImage "$DOWNLOAD_URL"; then
  echo "Download completed"
  chmod +x LosslessCut.AppImage
  mv LosslessCut.AppImage "$APPIMAGE_DIR/LosslessCut.AppImage"
  echo "Integrating with Gear Lever..."
  flatpak run it.mijorus.gearlever "$APPIMAGE_DIR/LosslessCut.AppImage" --no-gui
  echo "$APP_NAME installation completed"
else
  echo "Error: Failed to download $APP_NAME"
  rm -f LosslessCut.AppImage
  return 1
fi

cd -
