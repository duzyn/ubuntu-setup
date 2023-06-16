#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/AppImageCommunity/pkg2appimage/releases | \
    grep "pkg2appimage-.*-x86_64.AppImage" | grep browser_download_url | head -n 1 | cut -d '"' -f 4 | \
    sed -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | \
    xargs wget -O "$TEMP_DIR/pkg2appimage.AppImage"
mkdir -p "$HOME/Applications"
cp -f "$TEMP_DIR/pkg2appimage.AppImage" "$HOME/Applications"
chmod +x "$HOME/Applications/pkg2appimage.AppImage"
