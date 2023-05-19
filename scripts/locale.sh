#!/usr/bin/env bash

log "Installing Chinese language pack…"
sudo apt-get install -y \
  language-pack-gnome-zh-hans \
  language-pack-gnome-zh-hant \
  language-pack-zh-hans \
  language-pack-zh-hant
log "Installed Chinese language pack."


log "Installing some fonts…"
sudo apt-get install -y \
  fonts-arphic-ukai \
  fonts-arphic-uming \
  fonts-firacode \
  fonts-noto-cjk \
  fonts-noto-cjk-extra
log "Installed these fonts."


sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN