#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME=$1
    PACKAGE_NAME=$2
    PATTERN=$3
    API_URL=https://api.github.com/repos/$REPO_NAME/releases/latest
    VERSION_LATEST=$(wget -qO- "$API_URL" | jq -r ".tag_name" | tr -d "v")

    if dpkg -s "$PACKAGE_NAME" &>/dev/null; then
        VERSION_INSTALLED=$(dpkg -s "$PACKAGE_NAME" | grep Version: | cut -c 10- -)
        log "$PACKAGE_NAME $VERSION_INSTALLED is installed."
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]]; then
            log "$PACKAGE_NAME $VERSION_INSTALLED is lastest."
    else
        log "Installing $PACKAGE_NAME $VERSION_LATEST..."
        wget -O "$TMPDIR/$PACKAGE_NAME.deb" \
            "$(wget -O- "$API_URL" | jq -r ".assets[].browser_download_url" | \
                grep "${PATTERN}" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g")"
        sudo gdebi -n "$TMPDIR/$PACKAGE_NAME.deb"
    fi
}

# Pandoc
install_github_releases_apps jgm/pandoc pandoc amd64.deb

# LX Music
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb

# Hyper
install_github_releases_apps vercel/hyper hyper amd64.deb
# theme
if grep -q "plugins: \[\"hyper-material-theme\"\]" "$HOME/.hyper.js"; then
    log "hyper-material-theme is set."
else
    log "Setting theme to hyper-material-theme..."
    hyper i hyper-material-theme
fi

# DBeaver Community Edition
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb

# Zettlr
install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb

# Draw.io
install_github_releases_apps jgraph/drawio-desktop draw.io .deb

# GitHub Desktop
install_github_releases_apps shiftkey/desktop github-desktop .deb

# Flameshot
install_github_releases_apps flameshot-org/flameshot flameshot .ubuntu-20.04.amd64.deb

# Figma
install_github_releases_apps Figma-Linux/figma-linux figma-linux .amd64.deb

# PeaZip
install_github_releases_apps peazip/PeaZip peazip .GTK2-1_amd64.deb

# OpenBoard
install_github_releases_apps OpenBoard-org/OpenBoard openboard _20.04_.*_amd64.deb

# LocalSend
install_github_releases_apps localsend/localsend localsend .deb


