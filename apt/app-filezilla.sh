#!/bin/bash

set -e

# FileZilla - FTP client
# https://filezilla-project.org/

if command -v filezilla &>/dev/null; then
  echo "FileZilla is already installed, skipping..."
  return 0
fi

echo "Installing FileZilla..."

sudo apt update -y

if sudo apt install -y filezilla; then
  echo "FileZilla installation completed"
else
  echo "Error: Failed to install FileZilla"
  return 1
fi
