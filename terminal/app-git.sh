#!/bin/bash

set -e

# Git - Version control system
# https://git-scm.com/

if command -v git &>/dev/null; then
  echo "Git is already installed, skipping..."
  return 0
fi

echo "Installing Git..."

sudo apt update -y

if sudo apt install -y git; then
  echo "Git installation completed"
else
  echo "Error: Failed to install Git"
  return 1
fi
