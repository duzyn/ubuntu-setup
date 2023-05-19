#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/119-cn.html
if dpkg -s "gfie" &> /dev/null; then
  log "Greenfish Icon Editor Pro is installed."
else
  log "Downloading Greenfish Icon Editor Pro…"
  wget -O /tmp/gfie.deb http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
  log "Downloaded Greenfish Icon Editor Pro."

  log "Installing Greenfish Icon Editor Pro…"
  sudo gdebi -n /tmp/gfie.deb
  log "Installed Greenfish Icon Editor Pro."
fi
