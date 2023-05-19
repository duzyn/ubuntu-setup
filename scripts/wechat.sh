#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/119-cn.html
if dpkg -s "ukylin-wechat" &> /dev/null; then
  log "WeChat is installed."
else
  if dpkg -s "ukylin-wine" &> /dev/null; then
    log "Wine is installed."
  else
    log "Installing WeChat dependencies…"
    wget -O /tmp/ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n /tmp/ukylin-wine.deb
    log "Installed WeChat dependencies."
  fi

  log "Downloading WeChat…"
  wget -O /tmp/ukylin-wechat.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
  log "Downloaded WeChat."

  log "Installing WeChat…"
  sudo gdebi -n /tmp/ukylin-wechat.deb
  log "Installed WeChat."
fi
