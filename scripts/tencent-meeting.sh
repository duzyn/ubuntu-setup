#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/119-cn.html
if dpkg -s "ukylin-tencentmeeting" &> /dev/null; then
  log "Tencent Meeting is installed."
else
  if dpkg -s "ukylin-wine" &> /dev/null; then
    log "Wine is installed."
  else
    log "Installing Tencent Meeting dependencies…"
    wget -O /tmp/ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n /tmp/ukylin-wine.deb
    log "Installed Tencent Meeting dependencies."
  fi

  log "Downloading Tencent Meeting…"
  wget -O /tmp/ukylin-tencentmeeting.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64.deb
  log "Downloaded Tencent Meeting."

  log "Installing Tencent Meeting…"
  sudo gdebi -n /tmp/ukylin-tencentmeeting.deb
  log "Installed Tencent Meeting."
fi
