#!/usr/bin/env bash

# Usage: upgrade_github_hosted_apps jgraph/drawio-desktop draw.io

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

upgrade_github_hosted_apps() {
  local repo_name package_name version_latest version_installed
  repo_name=$1
  package_name=$2
  suffix=$3
  version_latest=$(curl "https://api.github.com/repos/${repo_name}/releases/latest" | jq -r ".tag_name" | tr -d "v")

  log "Trying to upgrade ${package_name}…"
  
  if dpkg -s "${package_name}" &> /dev/null; then
    version_installed=$(dpkg -s "${package_name}" | grep Version | tr -d "Version: ")
    log "Installed version is ${version_installed}."
  else
    version_installed=0
    log "Not installed ${package_name}."
  fi

  log "Got the latest version is ${version_latest}"
  if [[ "${version_latest}" != "${version_installed}" ]]; then
    log "Downloading ${package_name} ${version_latest}…"
    wget -O "/tmp/${package_name}.deb" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "https://api.github.com/repos/${repo_name}/releases/latest" | jq -r ".assets[].browser_download_url" | grep "$(if "${suffix}"; then echo "${suffix}"; else echo "amd64.deb"; fi) | head -n 1)"
    log "Downloaded ${package_name} ${version_latest}."

    log "Installing ${package_name} ${version_latest}…"
    sudo gdebi -n "/tmp/${package_name}.deb"
    log "Installed ${package_name} ${version_latest}."
  else
    log "You have installed latest version ${version_installed}, so there is no need to upgrade."
  fi
}