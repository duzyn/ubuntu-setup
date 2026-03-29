#!/bin/bash
set -euo pipefail

PACKAGES=(
  # Must have
  curl
  wget
  git
  aria2
  
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
  ghostscript
  rclone
  rclone-browser
  
  # Fonts
  fonts-noto-cjk
  fonts-firacode
  
  # Icons
  papirus-icon-theme
)

sudo apt-get install -y "${PACKAGES[@]}"
