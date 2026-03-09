#!/bin/bash

set -e

if command -v flatpak &>/dev/null; then
  exit 0
fi

sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
