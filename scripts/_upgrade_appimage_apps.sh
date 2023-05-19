#!/usr/bin/env bash

# Usage: upgrade_appimage_apps jgraph/drawio-desktop draw.io

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

upgrade_appimage_apps() {
  local repo_name package_name version_latest version_installed
  repo_name=$1
  package_name=$2
  version_latest=$(curl "https://api.github.com/repos/${repo_name}/releases/latest" | jq -r ".tag_name" | tr -d "v")

  if [[ -e "${HOME}/.${package_name}/VERSION" ]]; then
    version_installed=$(cat "${HOME}/.${package_name}/VERSION")
  else
    version_installed=0
  fi

  if [[ "${version_installed}" == "${version_latest}" ]]; then
    log "You have installed latest version ${version_installed}, so there is no need to upgrade."
  else
    # Remove old version
    [[ -e "${HOME}/Desktop/${package_name}.AppImage" ]] && rm -f "${HOME}/Desktop/${package_name}.AppImage"
    
    log "Downloading ${package_name} ${version_latest}…"
    wget -O "/tmp/${package_name}.AppImage" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "https://api.github.com/repos/${repo_name}/releases/latest" | jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1)"
    log "Downloaded ${package_name}."
    cp "/tmp/${package_name}.AppImage" "${HOME}/Desktop"
    chmod +x "${HOME}/Desktop/${package_name}.AppImage"

    echo "${version_latest}" > "${HOME}/.${package_name}/VERSION"
  fi
}
