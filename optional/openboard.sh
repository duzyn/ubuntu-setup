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

API_URL=https://api.github.com/repos/OpenBoard-org/OpenBoard/releases/latest
LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | grep tag_name | cut -f4 -d "\"" | tr -d "v")

if dpkg -s openboard &>/dev/null; then
    CURRENT_VERSION=$(dpkg -s openboard | grep ^Version: | cut -f2 -d " ")
else
    CURRENT_VERSION=noversion
fi

if ! [[ "$LATEST_VERSION" == *"$CURRENT_VERSION"* || "$CURRENT_VERSION" == *"$LATEST_VERSION"* ]]; then
    wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | \
        grep -Po "https://.+$(lsb_release -rs)_.*_amd64\.deb" | head -n 1 | \
        sed -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | \
        xargs wget -O "$TEMP_DIR/openboard.deb"
    if [[ -z "$(command -v gdebi)" ]]; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo gdebi -n "$TEMP_DIR/openboard.deb"
fi

rm -rf "$TEMP_DIR"
