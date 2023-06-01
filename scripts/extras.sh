#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo "Installing some extra apps..."
sudo apt-get install -y \
    android-sdk-platform-tools \
    audacity \
    calibre \
    digikam \
    filezilla \
    freecad \
    ghostscript \
    gimp \
    handbrake \
    imagemagick \
    inkscape \
    libvips-tools \
    mupdf \
    mupdf-tools \
    neofetch \
    network-manager-openvpn-gnome \
    obs-studio \
    openjdk-16-jdk \
    openshot \
    openvpn \
    pdfarranger \
    plank \
    scrcpy \
    scribus \
    subversion \
    vlc \
    wkhtmltopdf \
    xfce4-appmenu-plugin \
    xfce4-clipman-plugin
