#!/bin/bash
set -e

if ! command -v flatpak &>/dev/null; then
  sudo apt install -y flatpak
fi

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub
flatpak update --appstream

# Integrate AppImages
# https://github.com/mijorus/gearlever
if ! flatpak info it.mijorus.gearlever &>/dev/null; then
  flatpak install -y flathub it.mijorus.gearlever
fi
