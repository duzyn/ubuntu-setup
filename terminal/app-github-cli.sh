#!/bin/bash

set -e

# GitHub CLI - GitHub command line tool
# https://cli.github.com/

if command -v gh &>/dev/null; then
  echo "GitHub CLI is already installed, skipping..."
  return 0
fi

echo "Installing GitHub CLI..."

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -y

if sudo apt install -y gh; then
  echo "GitHub CLI installation completed"
else
  echo "Error: Failed to install GitHub CLI"
  return 1
fi
