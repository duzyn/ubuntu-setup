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

# Used for Ventoy VDisk boot
if [[ -e "$HOME/.vtoyboot/VERSION" ]]; then
    CURRENT_VERSION=$(cat "$HOME/.vtoyboot/VERSION")
else
    CURRENT_VERSION=noversion
fi

LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/repos/ventoy/vtoyboot/releases/latest | grep tag_name | head -n 1 | cut -f4 -d "\"" | tr -d "v")

if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    # Remove old version.
    [[ -d "$HOME/.vtoyboot" ]] && rm -rf "$HOME/.vtoyboot"

    # Install new version.
    wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" \
        https://api.github.com/repos/ventoy/vtoyboot/releases/latest | \
        grep -Po "https://.*\.iso" | head -n 1 | \
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
