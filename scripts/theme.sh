#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Theme
# WM: Materia: https://github.com/nana-4/materia-theme
# Icons: Papirus: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
if dpkg -s materia-gtk-theme &>/dev/null; then
    log "Materia GTK theme is installed."
else
    log "Installing Materia GTK theme..."
    sudo apt-get install -y materia-gtk-theme
fi

if dpkg -s papirus-icon-theme &>/dev/null; then
    log "Papirus icon theme is installed."
else
    log "Adding Papirus apt repository..."
    sudo add-apt-repository -y ppa:papirus/papirus

    log "Installing Papirus icon theme..."
    sudo apt-get update
    sudo apt-get install -y papirus-icon-theme
fi

log "Setting window manager theme to Materia..."
# For GTK3
gsettings set org.gnome.desktop.interface gtk-theme "Materia"
gsettings set org.gnome.desktop.wm.preferences theme "Materia"
# For GTK2
xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
xfconf-query -c xfwm4 -p /general/theme -s "Materia"

log "Setting icon theme to Papirus..."
gsettings set org.gnome.desktop.interface icon-theme "Papirus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"

log "Setting font family and size..."
xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Noto Sans Mono CJK SC 9"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"

# Hardcode-Tray: https://github.com/bilelmoussaoui/Hardcode-Tray
if dpkg -s hardcode-tray &>/dev/null; then
    log "Hardcode Tray is installed."
else
    log "Adding Hardcode Tray apt repository..."
    sudo add-apt-repository -y ppa:papirus/hardcode-tray

    log "Installing Hardcode Tray..."
    sudo apt-get update
    sudo apt-get install -y hardcode-tray
fi