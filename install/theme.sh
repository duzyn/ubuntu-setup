#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
: "${LOCALE:="zh_CN"}"

### Theme
# Window Manager: https://github.com/nana-4/materia-theme
# Icons: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
dpkg -s materia-gtk-theme &>/dev/null || sudo apt-get install -y materia-gtk-theme

if ! dpkg -s papirus-icon-theme &>/dev/null; then
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt-get update
    sudo apt-get install -y papirus-icon-theme
fi

# For GTK3
if [[ -n "$(command -v gsettings)" ]]; then
    gsettings set org.gnome.desktop.interface gtk-theme "Materia"
    gsettings set org.gnome.desktop.wm.preferences theme "Materia"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus"
fi

# For GTK2
if [[ -n "$(command -v xfconf-query)" ]]; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"
    xfconf-query -c xfwm4 -p /general/theme -s "Materia"
    xfconf-query -c xfce4-notifyd -p /theme -s "Default"

    # Fonts
    sudo apt-get install -y fonts-firacode fonts-open-sans
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Fira Code 10"
    if [[ "$LOCALE" == "zh_CN" ]]; then
        sudo apt-get install -y fonts-noto-cjk fonts-noto-cjk-extra
        xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
        xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"
    else
        xfconf-query -c xsettings -p /Gtk/FontName -s "Open Sans 10"
        xfconf-query -c xfwm4 -p /general/title_font -s "Open Sans 10"
    fi
fi

sudo apt-get install -y plank xfce4-appmenu-plugin
if [[ ! -e /etc/xdg/autostart/plank.desktop ]]; then
    sudo cp -f /usr/share/applications/plank.desktop /etc/xdg/autostart
fi


