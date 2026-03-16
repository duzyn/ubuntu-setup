#!/bin/bash
set -e

# Define NVM directory
export NVM_DIR="$HOME/.nvm"

# Install nvm if not present
if [ ! -d "$NVM_DIR" ]; then
  echo "Installing nvm from mirror..."
  # Use gh-proxy.com for raw.githubusercontent.com to ensure access in China
  curl -o- https://gh-proxy.com/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Load nvm for the current session
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
  echo "nvm could not be loaded. Please check your installation."
  return 1
fi

# Set Node.js download mirror
echo "Setting NVM_NODEJS_ORG_MIRROR to npmmirror..."
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

# Persist the mirror setting in .bashrc if not already present
if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$HOME/.bashrc"; then
  echo -e "\n# nvm node mirror\nexport NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node" >> "$HOME/.bashrc"
fi

# Install Node.js LTS
echo "Installing Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

# Set npm registry to China mirror
echo "Setting npm registry to https://registry.npmmirror.com..."
npm config set registry https://registry.npmmirror.com
