#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR="$(mktemp -d)"

### Tor Browser
API_URL="https://api.github.com/repos/TheTorProject/gettorbrowser/releases"
LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
    jq -r '.[].tag_name' | grep -Po "linux64-.+" | head -n 1 | cut -f2 -d "-")
CURRENT_VERSION=noversion
[[ -e "$HOME/.tor-browser/VERSION" ]] && CURRENT_VERSION=$(cat "$HOME/.tor-browser/VERSION")

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
        jq -r ".[].assets[].browser_download_url" | \
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
