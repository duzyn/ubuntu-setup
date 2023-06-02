#!/usr/bin/env bash

: "${GITHUB_TOKEN:="your_github_token"}"
export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Tor Browser
TOR_BROWSER_LATEST_VERSION=$(wget -qO- --header "Authorization: $GITHUB_TOKEN" "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" |
    jq -r ".tag_name" | sed "s/.*-//g")

if [[ -e "$HOME/.tor-browser/VERSION" ]]; then
    TOR_BROWSER_INSTALLED_VERSION=$(cat "$HOME/.tor-browser/VERSION")
    echo "Tor Browser $TOR_BROWSER_INSTALLED_VERSION is installed."
else
    TOR_BROWSER_INSTALLED_VERSION=not_installed
    echo "Tor Browser doesn't exist."
fi

if [[ "$TOR_BROWSER_INSTALLED_VERSION" != "$TOR_BROWSER_LATEST_VERSION" ]]; then

    echo "Downloading Tor Browser..."
    wget -O "$TMPDIR/tor-browser.tar.xz" "https://ghproxy.com/https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${TOR_BROWSER_LATEST_VERSION}/tor-browser-linux64-${TOR_BROWSER_LATEST_VERSION}_ALL.tar.xz"

    # Remove old version.
    if [[ -f "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" ]]; then
        "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --unregister-app
    fi
    [[ -d "$HOME/.tor-browser/tor-browser" ]] && rm -rf "$HOME/.tor-browser/tor-browser"

    # Install new version.
    echo "Installing Tor Browser..."
    [[ -d "$HOME/.tor-browser" ]] || mkdir -p "$HOME/.tor-browser"
    tar --extract --xz --directory "$HOME/.tor-browser" --file "$TMPDIR/tor-browser.tar.xz"
    "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --register-app

    # Record version
    echo "$TOR_BROWSER_LATEST_VERSION" >"$HOME/.tor-browser/VERSION"
else
    echo "Tor Browser $TOR_BROWSER_INSTALLED_VERSION is latest."
fi
