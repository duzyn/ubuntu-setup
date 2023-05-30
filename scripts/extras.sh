#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

log "Installing some extra apps..."
sudo apt-get install -y \
    android-sdk-platform-tools \
    audacity \
    calibre \
    digikam \
    filezilla \
    flameshot \
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
    xfce4-appmenu-plugin
