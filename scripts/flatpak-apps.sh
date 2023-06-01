#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Flatpak: https://flatpak.org/setup/Ubuntu
if [[ -x "$(command -v flatpak)" ]]; then
    echo "Flatpak is installed."
else
    echo "Installing Flatpak..."
    sudo apt-get install -y flatpak gnome-software-plugin-flatpak

    echo "Adding Flatpak remote repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "To complete setup, restart your system. run: sudo shutdown -r now"
    exit 0
fi

# flatpak install --or-update -y flathub net.cozic.joplin_desktop
# flatpak install --or-update -y flathub net.xmind.XMind
# flatpak install --or-update -y flathub org.localsend.localsend_app
# flatpak install --or-update -y flathub com.github.hluk.copyq # ppa copyq can't startup
