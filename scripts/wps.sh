#!/usr/bin/env bash

if dpkg -s "wps-office" &> /dev/null; then
  log "WPS is installed."
else
  log "Downloading WPS…"
  wget -O /tmp/wps-office.deb https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
  log "Downloaded WPS."

  log "Installing WPS…"
  sudo gdebi -n /tmp/wps-office.deb
  log "Installed WPS."

  # # Install symbol fonts.
  # if [ ! -f "wps_symbol_fonts.zip" ]; then
  #   log "wps_symbol_fonts.zip not exist, exit…"
  #   exit 1
  # fi

  # log "unzip file wps_symbol_fonts.zip …"
  # unzip wps_symbol_fonts.zip -d wps_symbol_fonts
  # if [ 0 -ne $? ]; then
  #     log "unzip wps_symbol_fonts.zip failed, exit…"
  #     exit 1
  # fi

  # log "mv wps_symbol_fonts to /usr/share/fonts/ …"
  # sudo mv wps_symbol_fonts /usr/share/fonts/
  # if [ 0 -ne $? ]; then
  #     log "mv wps_symbol_fonts to /usr/share/fonts/ failed, exit…"
  #     exit 1
  # fi

  # cd /usr/share/fonts/wps_symbol_fonts/
  # if [ 0 -ne $? ]; then
  #     log "cd to /usr/share/fonts/ failed, exit…"
  #     exit 1
  # fi

  # sudo mkfontscale
  # if [ 0 -ne $? ]; then
  #     log "sudo mkfontscale failed, exit…"
  #     exit 1
  # fi

  # sudo mkfontdir
  # if [ 0 -ne $? ]; then
  #     log "sudo mkfontdir, exit…"
  #     exit 1
  # fi

  # sudo fc-cache
  # if [ 0 -ne $? ]; then
  #     log "sudo fc-cache, exit…"
  #     exit 1
  # fi

fi