#!/bin/bash

set -e

# Essential command line tools

echo "Installing command line tools..."

sudo apt update -y

# jq - JSON processor
echo "Installing jq..."
if ! sudo apt install -y jq; then
  echo "Error: Failed to install jq"
  return 1
fi

# ripgrep - Fast text search
echo "Installing ripgrep..."
if ! sudo apt install -y ripgrep; then
  echo "Error: Failed to install ripgrep"
  return 1
fi

# wget and curl (usually already installed)
echo "Installing wget and curl..."
if ! sudo apt install -y wget curl; then
  echo "Error: Failed to install wget and curl"
  return 1
fi

# aria2 - Download utility
echo "Installing aria2..."
if ! sudo apt install -y aria2; then
  echo "Error: Failed to install aria2"
  return 1
fi

# ffmpeg - Multimedia framework
echo "Installing ffmpeg..."
if ! sudo apt install -y ffmpeg; then
  echo "Error: Failed to install ffmpeg"
  return 1
fi

# imagemagick - Image manipulation
echo "Installing imagemagick..."
if ! sudo apt install -y imagemagick; then
  echo "Error: Failed to install imagemagick"
  return 1
fi

echo "Command line tools installation completed"
