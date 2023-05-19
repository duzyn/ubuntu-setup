#!/usr/bin/env bash

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

install_tor_browser() {
  local version_latest version_installed
  version_latest=$(curl "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" | jq -r ".tag_name" | sed "s/.*-//g")

  if [[ -e "${HOME}/.tor-browser/VERSION" ]]; then
    version_installed=$(cat "${HOME}/.tor-browser/VERSION")
  else
    version_installed=0
  fi

  if [[ "${version_installed}" == "${version_latest}" ]]; then
    log "You have installed latest version ${version_installed}, so there is no need to upgrade."
  else
    [[ -d "${HOME}/tor-browser" ]] && rm -rf "${HOME}/tor-browser"

    log "Downloading Tor Browser ${version_latest}…"
    wget -O "/tmp/tor-browser.tar.xz" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${version_latest}/tor-browser-linux64-${version_latest}_ALL.tar.xz"
    log "Downloaded Tor Browser."

    7z x -o/tmp/tor-browser /tmp/tor-browser.tar.xz
    7z x -o/tmp/tor-browser /tmp/tor-browser/tor-browser.tar
    cp -r /tmp/tor-browser/tor-browser "${HOME}/"

    echo "${version_latest}" > "${HOME}/.tor-browser/VERSION"
  fi
}

install_tor_browser
