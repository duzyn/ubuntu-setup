#!/usr/bin/env bash

# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME="$1"
    PACKAGE_NAME="$2"
    PATTERN="$3"
    API_URL="https://api.github.com/repos/$REPO_NAME/releases/latest"
    VERSION_LATEST="$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" |
        jq -r '.tag_name' | tr -d "v")"
    VERSION_INSTALLED="$(get_package_version "$PACKAGE_NAME")"

    if ! [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* ||
        "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]]; then
        wget -O- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
            jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1 | \
            sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | \
            xargs wget -O "$TEMP_DIR/$PACKAGE_NAME.deb"
        sudo gdebi -n "$TEMP_DIR/$PACKAGE_NAME.deb"
    fi
}
