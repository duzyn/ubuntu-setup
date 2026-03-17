#!/bin/bash

set -e

# Starship - Cross-shell prompt
# https://starship.rs/

if command -v starship &>/dev/null; then
  echo "Starship is already installed, skipping..."
  return 0
fi

echo "Installing Starship..."

cd /tmp

STARSHIP_URL="https://gh-proxy.com/https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz"

echo "Downloading Starship..."
if wget -O starship.tar.gz "$STARSHIP_URL"; then
  echo "Download completed"
  echo "Installing Starship..."
  tar -xzf starship.tar.gz
  sudo mv starship /usr/local/bin/
  rm -f starship.tar.gz
  echo "Starship installation completed"
else
  echo "Error: Failed to download Starship"
  rm -f starship.tar.gz
  return 1
fi

cd -

if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
  echo -e "\n# Starship prompt" >> "$HOME/.bashrc"
  echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

echo "Please restart your terminal or run: source ~/.bashrc"
