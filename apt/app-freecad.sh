#!/bin/bash

set -e

# FreeCAD - Open source CAD
# https://www.freecad.org/

if command -v freecad &>/dev/null; then
  echo "FreeCAD is already installed, skipping..."
  return 0
fi

echo "Installing FreeCAD..."

sudo apt update -y

if sudo apt install -y freecad; then
  echo "FreeCAD installation completed"
else
  echo "Error: Failed to install FreeCAD"
  return 1
fi
