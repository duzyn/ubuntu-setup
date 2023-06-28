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

TEMP_DIR=$(mktemp -d)

# https://github.com/sqlitebrowser/sqlitebrowser/releases/latest
URL=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/sqlitebrowser/sqlitebrowser/releases/latest | \
    grep -Po "https://.+\.AppImage" | head -n 1 | \
    sed -e "s|https://github.com|https://ghproxy.com/https://github.com|g")
FILENAME=$(basename "$URL")
LATEST_VERSION=$(echo "$FILENAME" | cut -f2 -d "-" | tr -d "v")

if find "$HOME/Applications/" -name "DB_Browser_for_SQLite*" | grep -q .; then
    CURRENT_VERSION=$(find "$HOME/Applications/" -name "DB_Browser_for_SQLite*" | cut -f2 -d "-" | tr -d "v")
else
    CURRENT_VERSION=noversion
fi

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    wget -c -O "$TEMP_DIR/$FILENAME" "$URL"
    cp -f "$TEMP_DIR/$FILENAME" "$HOME/Applications/"
    chmod +x "$HOME/Applications/$FILENAME"

    # Desktop entry
    wget -c -O "$HOME/.local/share/applications/sqlitebrowser.desktop" https://ghproxy.com/https://github.com/sqlitebrowser/sqlitebrowser/raw/master/distri/sqlitebrowser.desktop
    sed -i -e "s|Exec=.*|Exec=$HOME/Applications/$FILENAME %f|g" "$HOME/.local/share/applications/sqlitebrowser.desktop"

    # Icon
    wget -c -O "$HOME/.local/share/icons/hicolor/scalable/apps/sqlitebrowser.svg" https://ghproxy.com/https://github.com/sqlitebrowser/sqlitebrowser/raw/master/images/logo.svg

fi

rm -rf "$TEMP_DIR"
