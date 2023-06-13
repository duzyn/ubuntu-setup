#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

. ../lib/install_github_releases_apps.sh

# GitHub Releases apps
# install_github_releases_apps bitwarden/clients bitwarden amd64.deb
# install_github_releases_apps vercel/hyper hyper amd64.deb
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
install_github_releases_apps Figma-Linux/figma-linux figma-linux .amd64.deb
install_github_releases_apps flameshot-org/flameshot flameshot "ubuntu-$(lsb_release -rs).amd64.deb"
install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps jgraph/drawio-desktop draw.io .deb
install_github_releases_apps localsend/localsend localsend .deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb
install_github_releases_apps OpenBoard-org/OpenBoard openboard "$(lsb_release -rs)_.*_amd64.deb"
install_github_releases_apps peazip/PeaZip peazip .GTK2-1_amd64.deb
install_github_releases_apps shiftkey/desktop github-desktop .deb
install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb

