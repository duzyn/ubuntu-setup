#!/bin/bash
set -euo pipefail

# apt.sh - Install applications from Ubuntu apt repositories
# Usage: sudo ./apt.sh

# Define packages to install
# Add new package names here
PACKAGES=(
  # Development tools
  adb
  scrcpy
  apktool
  jq
  ripgrep
  
  # Multimedia
  audacity
  vlc
  obs-studio
  gimp
  inkscape
  
  # Office & Productivity
  calibre
  libreoffice
  thunderbird
  keepassxc
  copyq
  pandoc
  scribus
  
  # Graphics & Photography
  digikam
  flameshot
  freecad
  pdfarranger
  
  # System & Utilities
  filezilla
  plank
  ghostscript
  
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
