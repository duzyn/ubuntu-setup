#!/bin/bash

set -e

# Android development tools: ADB, Scrcpy, Apktool

echo "Installing Android development tools..."

sudo apt update -y

# ADB (Android Debug Bridge)
if ! command -v adb &>/dev/null; then
  echo "Installing ADB..."
  if ! sudo apt install -y adb; then
    echo "Error: Failed to install ADB"
    return 1
  fi
fi

# Scrcpy - Screen mirroring and control
if ! command -v scrcpy &>/dev/null; then
  echo "Installing Scrcpy..."
  if ! sudo apt install -y scrcpy; then
    echo "Error: Failed to install Scrcpy"
    return 1
  fi
fi

# Apktool - APK reverse engineering
if ! command -v apktool &>/dev/null; then
  echo "Installing Apktool..."
  if ! sudo apt install -y apktool; then
    echo "Error: Failed to install Apktool"
    return 1
  fi
fi

echo "Android tools installation completed"
