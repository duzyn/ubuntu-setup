#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Used for Ventoy VDisk boot
LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")
CURRENT_VERSION=noversion
[[ -e "$HOME/.vtoyboot/VERSION" ]] && CURRENT_VERSION=$(cat "$HOME/.vtoyboot/VERSION")

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    # Remove old version.
    [[ -d "$HOME/.vtoyboot" ]] && rm -rf "$HOME/.vtoyboot"

    # Install new version.
    wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/ventoy/vtoyboot/releases/latest | \
        jq -r ".assets[].browser_download_url" | grep .iso | head -n 1 | \
        sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | \
        xargs wget -O "$TEMP_DIR/vtoyboot.iso"

    7z x -o"$TEMP_DIR" "$TEMP_DIR/vtoyboot.iso"
    mkdir -p "$HOME/.vtoyboot"
    tar --extract --gz --directory "$HOME/.vtoyboot" \
        --file "$TEMP_DIR/vtoyboot-$LATEST_VERSION.tar.gz"

    # Record version.
    echo "$LATEST_VERSION" >"$HOME/.vtoyboot/VERSION"
fi

cd "$HOME/.vtoyboot/vtoyboot-$LATEST_VERSION" || exit 1
sudo bash "./vtoyboot.sh"
cd "$OLDPWD" || exit 1
echo "Completed!" && exit 0

rm -rf "$TEMP_DIR"
