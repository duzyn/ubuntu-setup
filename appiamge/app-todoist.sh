#!/bin/bash

set -e

# Todoist - Task management
# https://todoist.com/

if command -v todoist &>/dev/null || [ -f "/opt/Todoist/todoist" ]; then
  echo "Todoist is already installed, skipping..."
  return 0
fi

echo "Installing Todoist..."

# Todoist has NO official deb package for Linux, only Flatpak/Snap
echo "Error: Todoist has no official deb package available"
echo "Available alternatives: Flatpak or Snap (not deb-based)"
return 1
