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
TEMP_DIR="$(mktemp -d)"

# Tor Browser
# It's recommended using Tor Browser to update itself
API_URL="https://api.github.com/repos/TheTorProject/gettorbrowser/releases"
LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
    grep tag_name | grep "linux64-" | head -n 1 | cut -f4 -d "\"" | cut -f2 -d "-")

if [[ -e "$HOME/.tor-browser/VERSION" ]]; then
    CURRENT_VERSION=$(cat "$HOME/.tor-browser/VERSION")
else
    CURRENT_VERSION=noversion
fi

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
        grep -Po "https://.+linux64-.+_ALL\.tar\.xz" | head -n 1 | \
        sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | \
        xargs wget -O "$TEMP_DIR/tor-browser.tar.xz"

    # Remove old version.
    [[ -f "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" ]] && \
        "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --unregister-app

    [[ -d "$HOME/.tor-browser/tor-browser" ]] && rm -rf "$HOME/.tor-browser/tor-browser"

    # Install new version.
    mkdir -p "$HOME/.tor-browser"
    tar --extract --xz --directory "$HOME/.tor-browser" --file "$TEMP_DIR/tor-browser.tar.xz"
    "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --register-app

    # Record version
    echo "$LATEST_VERSION" >"$HOME/.tor-browser/VERSION"
fi

mkdir -p "$HOME/.config/autostart"
[[ ! -e "$HOME/.config/autostart/start-tor-browser.desktop" ]] && \
    cp -f "$HOME/.local/share/applications/start-tor-browser.desktop" "$HOME/.config/autostart"

rm -rf "$TEMP_DIR"
