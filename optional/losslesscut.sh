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

. ../lib/install_appimage_apps.sh

# Losslesscut
install_appimage_apps mifi/lossless-cut losslesscut
if [[ ! -e "$HOME/.local/share/icons/hicolor/scalable/apps/losslesscut.svg" ]]; then
    wget -O "$TEMP_DIR/losslesscut.svg" \
        https://ghproxy.com/https://github.com/mifi/lossless-cut/raw/master/src/icon.svg
    sudo mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
    sudo mv "$TEMP_DIR/losslesscut.svg" "$HOME/.local/share/icons/hicolor/scalable/apps"
fi

mkdir -p "$HOME/.local/share/applications"
wget -O "$TEMP_DIR/losslesscut.desktop" \
    https://ghproxy.com/https://github.com/mifi/lossless-cut/raw/master/no.mifi.losslesscut.desktop
sudo mv "$TEMP_DIR/losslesscut.desktop" "$HOME/.local/share/applications/losslesscut.desktop"
sudo sed -i -e "s|Exec=.*|Exec=$HOME/.AppImageApplications/losslesscut.AppImage %u|g" \
    "$HOME/.local/share/applications/losslesscut.desktop"

update-desktop-database "$HOME/.local/share/applications"