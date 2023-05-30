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

install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb
# install_github_releases_apps vercel/hyper hyper amd64.deb
# install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
# install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb
# install_github_releases_apps jgraph/drawio-desktop draw.io .deb
# install_github_releases_apps shiftkey/desktop github-desktop .deb