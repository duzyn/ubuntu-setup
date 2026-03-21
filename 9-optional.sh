#!/bin/bash
set -euo pipefail

# apt.sh - Install applications from Ubuntu apt repositories
# Usage: sudo ./1-apt.sh

# Define packages to install
# Add new package names here
PACKAGES=(
  freecad
  calibre
  libreoffice
  digikam
  vlc
  gimp
  pdfarranger
)

echo "Installing apt packages..."

# Update package list
sudo apt-get update

# Install all packages
sudo apt-get install -y "${PACKAGES[@]}"

echo "All packages installed successfully!"
