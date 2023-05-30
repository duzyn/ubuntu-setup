#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Flatpak: https://flatpak.org/setup/Ubuntu
if [[ -x "$(command -v flatpak)" ]]; then
    log "Flatpak is installed."
else
    log "Installing Flatpak..."
    sudo apt-get install -y flatpak gnome-software-plugin-flatpak

    log "Adding Flatpak remote repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    die "To complete setup, restart your system. run: sudo shutdown -r now" 0
fi

flatpak install --or-update -y flathub com.bitwarden.desktop
flatpak install --or-update -y flathub com.jgraph.drawio.desktop
flatpak install --or-update -y flathub com.zettlr.Zettlr
flatpak install --or-update -y flathub io.dbeaver.DBeaverCommunity
flatpak install --or-update -y flathub io.github.Figma_Linux.figma_linux
flatpak install --or-update -y flathub io.github.peazip.PeaZip
flatpak install --or-update -y flathub io.github.shiftey.Desktop
flatpak install --or-update -y flathub net.cozic.joplin_desktop
flatpak install --or-update -y flathub net.xmind.XMind
flatpak install --or-update -y flathub org.localsend.localsend_app