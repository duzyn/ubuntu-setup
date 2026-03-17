#!/bin/bash

set -e

# FUSE - Filesystem in Userspace (required for rclone mount, Cryptomator, etc.)
# https://github.com/libfuse/libfuse

if dpkg -l | grep -q "^ii.*fuse3"; then
  echo "FUSE is already installed, skipping..."
  return 0
fi

echo "Installing FUSE..."

sudo apt update -y

if sudo apt install -y fuse3 libfuse3-dev; then
  echo "FUSE installation completed"
else
  echo "Error: Failed to install FUSE"
  return 1
fi

if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
  echo "user_allow_other" | sudo tee -a /etc/fuse.conf
fi
