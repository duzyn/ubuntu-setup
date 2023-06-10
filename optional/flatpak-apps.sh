#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Flatpak: https://flatpak.org/setup/Ubuntu
sudo apt-get install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# flatpak install --or-update -y flathub net.cozic.joplin_desktop
# flatpak install --or-update -y flathub net.xmind.XMind
# flatpak install --or-update -y flathub org.localsend.localsend_app
