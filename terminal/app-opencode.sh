#!/bin/bash
set -e

# Ensure Node.js and npm are installed
if ! command -v npm &>/dev/null; then
  echo "npm not found. Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

# Install opencode globally
if ! command -v opencode &>/dev/null; then
  echo "Installing opencode..."
  sudo npm install -g opencode
else
  echo "opencode is already installed."
fi

# Install oh-my-opencode globally
if ! npm list -g oh-my-opencode &>/dev/null; then
  echo "Installing oh-my-opencode..."
  sudo npm install -g oh-my-opencode
else
  echo "oh-my-opencode is already installed."
fi
