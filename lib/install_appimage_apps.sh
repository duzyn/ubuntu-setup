#!/usr/bin/env bash

# Installing 3rd party .AppImage apps from GitHub Releases
install_appimage_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED
    REPO_NAME="$1"
    PACKAGE_NAME="$2"
    API_URL="https://api.github.com/repos/$REPO_NAME/releases/latest"
    VERSION_LATEST="$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
        grep tag_name | head -n 1 | cut -f4 -d "\"" | tr -d "v")"

    if [[ -e "$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION" ]]; then
        VERSION_INSTALLED=$(cat "$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION")
    else
        VERSION_INSTALLED="not_installed"
    fi

    if ! [[ "$VERSION_INSTALLED" == *"$VERSION_LATEST"* || \
        "$VERSION_LATEST" == *"$VERSION_INSTALLED"* ]]; then
        # Remove old version
        [[ -e "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage" ]] && \
            rm -f "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage"

        wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
            grep -Po "https://.*\.AppImage" | head -n 1 | \
            sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | \
            xargs wget -O "$TEMP_DIR/$PACKAGE_NAME.AppImage"

        # Install new version
        mkdir -p "$HOME/.AppImageApplications"
        cp "$TEMP_DIR/$PACKAGE_NAME.AppImage" "$HOME/.AppImageApplications"
        chmod +x "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage"

        # Record version
        echo "$VERSION_LATEST" >"$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION"
    fi
}
