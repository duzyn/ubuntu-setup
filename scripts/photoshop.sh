#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/119-cn.html
if dpkg -s "ukylin-ps6" &> /dev/null; then
  log "Photoshop is installed."
else
  if dpkg -s "ukylin-wine" &> /dev/null; then
    log "Wine is installed."
  else
    log "Installing Photoshop dependencies…"
    wget -O /tmp/ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n /tmp/ukylin-wine.deb
    log "Installed Photoshop dependencies."
  fi

  log "Downloading Photoshop…"
  wget -O /tmp/ukylin-ps6.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
  log "Downloaded Photoshop."

  log "Installing Photoshop…"
  sudo gdebi -n /tmp/ukylin-ps6.deb
  log "Installed Photoshop."
fi
