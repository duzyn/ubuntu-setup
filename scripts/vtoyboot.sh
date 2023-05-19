#!/usr/bin/env bash

run_vtoyboot() {
  local api_url version_latest
  api_url=https://api.github.com/repos/ventoy/vtoyboot/releases/latest
  version_latest=$(curl "${api_url}" | jq -r ".tag_name" | tr -d "v")
  log "Downloading vtoyboot ${version_latest}…"
  wget -O "/tmp/vtoyboot.iso" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "${api_url}" | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
  log "Downloaded vtoyboot."

  log "Run vtoyboot"
  7z x -o/tmp/vtoyboot /tmp/vtoyboot.iso
  7z x -o/tmp/vtoyboot /tmp/vtoyboot/*.tar.gz
  7z x -o/tmp/vtoyboot /tmp/vtoyboot/*.tar
  sudo bash "/tmp/vtoyboot/vtoyboot-${version_latest}/vtoyboot.sh"
}
run_vtoyboot
