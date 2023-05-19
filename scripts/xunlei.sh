#!/usr/bin/env bash

# https://www.ubuntukylin.com/applications/119-cn.html
if dpkg -s "xunlei" &> /dev/null; then
  log "Xunlei is installed."
else
  log "Downloading Xunlei…"
  wget -O /tmp/xunlei.deb https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
  log "Downloaded Xunlei."

  log "Installing Xunlei…"
  sudo gdebi -n /tmp/xunlei.deb
  log "Installed Xunlei."
fi
