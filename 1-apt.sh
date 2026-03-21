#!/bin/bash
set -euo pipefail

# apt.sh - Install applications from Ubuntu apt repositories
# Usage: sudo ./1-apt.sh

# Define packages to install
# Add new package names here
PACKAGES=(
  # Must have
  curl
  wget
  git
  
  # Archive
  7zip
  unrar
  unzip

  # Development tools
  adb
  scrcpy
  apktool
  jq
  ripgrep
  fzf
  
  # Multimedia
  audacity
  obs-studio
  inkscape
  
  # Office & Productivity
  thunderbird
  keepassxc
  copyq
  pandoc
  scribus
  mupdf-tools
  
  # Graphics & Photography
  flameshot
  libvips
  
  # System & Utilities
  filezilla
  plank
  ghostscript
  rclone
  
  # Fonts
  fonts-noto-cjk
  fonts-firacode
  
  # Icons
  papirus-icon-theme
)

echo "Installing apt packages..."

# Update package list
sudo apt-get update

# Install all packages
sudo apt-get install -y "${PACKAGES[@]}"

echo "All packages installed successfully!"
