#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Fonts
log "Installing some fonts..."
sudo apt-get install -y \
    fonts-cascadia-code \
    fonts-emojione \
    fonts-firacode \
    fonts-noto-color-emoji \
    fonts-open-sans \
    fonts-roboto \
    fonts-ubuntu

# Locale
if [[ $LOCALE == "zh_CN" ]]; then
    log "Installing Chinese language pack..."
    sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans

    log "Installing Chinese fonts..."
    sudo apt-get install -y \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-noto-cjk \
        fonts-noto-cjk-extra
fi

log "Changing locale to $LOCALE..."
sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"

# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
# cat ~/.config/user-dirs.dirs
log "Setting user dirs name..."
cd "$HOME" && mkdir -p Desktop Documents Download Music Pictures Publicshare Templates Videos
xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
xdg-user-dirs-update --set DOWNLOAD "$HOME/Download"
xdg-user-dirs-update --set MUSIC "$HOME/Music"
xdg-user-dirs-update --set PICTURES "$HOME/Pictures"
xdg-user-dirs-update --set PUBLICSHARE "$HOME/Publicshare"
xdg-user-dirs-update --set TEMPLATES "$HOME/Templates"
xdg-user-dirs-update --set VIDEOS "$HOME/Videos"
