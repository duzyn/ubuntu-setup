#!/bin/bash
set -e

# Install Flatpak if not already installed
if ! command -v flatpak &>/dev/null; then
  sudo apt install -y flatpak
fi

# Add Flathub repository if it doesn't exist
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Configure SJTU Mirror
# See: https://mirror.sjtu.edu.cn/docs/flathub
CURRENT_URL=$(flatpak remotes --columns=name,url | grep "^flathub" | awk '{print $2}')
TARGET_URL="https://mirror.sjtu.edu.cn/flathub"

if [ "$CURRENT_URL" != "$TARGET_URL" ]; then
  echo "Configuring SJTU Flathub mirror..."
  sudo flatpak remote-modify flathub --url="$TARGET_URL"
  
  # Import SJTU Flathub GPG key for reliability
  cd /tmp
  wget -q https://mirror.sjtu.edu.cn/flathub/flathub.gpg
  sudo flatpak remote-modify --gpg-import=flathub.gpg flathub
  rm flathub.gpg
  cd - > /dev/null
fi
