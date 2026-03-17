#!/bin/bash

set -e

# WeChat for Linux - Official Tencent version
# https://linux.weixin.qq.com/

APP_NAME="wechat"
DOWNLOAD_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"
TEMP_FILE="/tmp/wechat.deb"

if command -v wechat &>/dev/null || command -v electronic-wechat &>/dev/null; then
  echo "WeChat is already installed, skipping..."
  return 0
fi

echo "Installing WeChat..."
echo "Fetching latest version..."

VERSION=$(curl -sL "https://linux.weixin.qq.com/" | grep -oP '\d+\.\d+\.\d+' | head -1)

if [[ -n "$VERSION" ]]; then
  echo "Latest version: ${VERSION}"
fi

echo "Downloading WeChat..."

if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
  echo "Error: Failed to download WeChat"
  rm -f "$TEMP_FILE"
  return 1
fi

echo "Download completed"
echo "Installing WeChat..."

if ! sudo apt install -y "$TEMP_FILE"; then
  echo "Error: Failed to install WeChat"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
echo "WeChat installation completed"
