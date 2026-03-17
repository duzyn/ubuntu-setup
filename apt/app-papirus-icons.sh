#!/bin/bash

set -e

# Papirus Icon Theme
# https://github.com/PapirusDevelopmentTeam/papirus-icon-theme

if [ -d "/usr/share/icons/Papirus" ] || [ -d "$HOME/.icons/Papirus" ]; then
  echo "Papirus Icon Theme is already installed, skipping..."
  return 0
fi

echo "Installing Papirus Icon Theme..."

# Papirus doesn't provide deb packages in GitHub releases
# Installing via apt from Ubuntu repositories
if sudo apt install -y papirus-icon-theme; then
  echo "Papirus Icon Theme installation completed"
else
  echo "Error: Failed to install Papirus Icon Theme"
  return 1
fi
