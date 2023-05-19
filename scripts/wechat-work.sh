#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/108-cn.html
if dpkg -s "ukylin-wxwork" &> /dev/null; then
  log "WeChat Work is installed."
else
  if dpkg -s "ukylin-wine" &> /dev/null; then
    log "Wine is installed."
  else
    log "Installing WeChat Work dependencies…"
    wget -O /tmp/ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n /tmp/ukylin-wine.deb
    log "Installed WeChat Work dependencies."
  fi

  log "Downloading WeChat Work…"
  wget -O /tmp/ukylin-wxwork.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
  log "Downloaded WeChat Work."

  log "Installing WeChat Work…"
  sudo gdebi -n /tmp/ukylin-wxwork.deb
  log "Installed WeChat Work."
fi
