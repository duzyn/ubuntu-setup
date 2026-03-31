#!/bin/bash

set -e

# GitHub proxy (optional)
GH_PROXY="${GH_PROXY:-}"

# Node.js via nvm
# https://nodejs.org/

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  echo "Installing nvm..."
  
  cd /tmp
  
  NVM_URL="${GH_PROXY}https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
  
  if wget -O install.sh "$NVM_URL"; then
  echo "Download completed"
  echo "Installing nvm..."
  bash install.sh
  rm -f install.sh
  else
  echo "Error: Failed to download nvm"
  rm -f install.sh
  return 1
  fi
  
  cd -
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
  echo "Error: nvm could not be loaded"
  return 1
fi

export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

if grep -q "NVM_NODEJS_ORG_MIRROR" "$HOME/.bashrc"; then
  # Replace existing mirror setting
  sed -i 's|export NVM_NODEJS_ORG_MIRROR=.*|export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node|' "$HOME/.bashrc"
else
  # Add new mirror setting
  echo -e "export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node" >> "$HOME/.bashrc"
fi

echo "Installing Node.js LTS..."
nvm install --lts
nvm use --lts

echo "Setting npm registry to https://registry.npmmirror.com..."
npm config set registry https://registry.npmmirror.com

echo "Updating npm"
npm update -g npm

# Install or update opencode globally
# echo "Checking opencode installation..."
# if command -v opencode &>/dev/null; then
#   echo "opencode is already installed, updating..."
#   npm update -g opencode-ai
# else
#   echo "Installing opencode..."
#   npm install -g opencode-ai
# fi

echo "Checking oh-my-opencode installation..."
if [ ! -f "$HOME/.config/opencode/oh-my-opencode.json" ] && [ ! -f "$HOME/.config/opencode/oh-my-opencode.jsonc" ]; then
  echo "Installing oh-my-opencode..."
  npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no
fi

echo "Node.js installation completed"
echo ""
echo "Next steps:"
echo "  Run 'source ~/.bashrc' to reload shell configuration"
