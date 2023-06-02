#!/usr/bin/env bash

: "${VTOYBOOT:="false"}"
: "${GITHUB_TOKEN:="your_github_token"}"

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Used for Ventoy VDisk boot
if [[ "$VTOYBOOT" == "true" ]]; then
    VTOY_LATEST_VERSION=$(wget --show-progress -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")
    VTOY_INSTALLED_VERSION=not_installed
    [[ -e "$HOME/.vtoyboot/VERSION" ]] && VTOY_INSTALLED_VERSION=$(cat "$HOME/.vtoyboot/VERSION")

    if [[ "$VTOY_INSTALLED_VERSION" != "$VTOY_LATEST_VERSION" ]]; then
        # Remove old version.
        [[ -d "$HOME/.vtoyboot" ]] && rm -r "$HOME/.vtoyboot"

        # Install new version.
        echo "Downloading vtoyboot $VTOY_LATEST_VERSION..."
        wget --show-progress -O "$TMPDIR/vtoyboot.iso" "$(wget --show-progress -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | \
            jq -r ".assets[].browser_download_url" | grep .iso | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g")"

        7z x -o"$TMPDIR" "$TMPDIR/vtoyboot.iso"
        [[ -d "$HOME/.vtoyboot" ]] || mkdir -p "$HOME/.vtoyboot"
        tar --extract --gz --directory "$HOME/.vtoyboot" --file "$TMPDIR/vtoyboot-$VTOY_LATEST_VERSION.tar.gz"

        # Record version.
        echo "$VTOY_LATEST_VERSION" >"$HOME/.vtoyboot/VERSION"
    fi

    cd "$HOME/.vtoyboot/vtoyboot-$VTOY_LATEST_VERSION" || echo "No vtoyboot folder."
    echo "Running vtoyboot..."
    sudo bash "./vtoyboot.sh"

    echo "Completed! You can poweroff vbox, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder." && exit 0
fi