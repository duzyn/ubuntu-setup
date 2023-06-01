#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)


# https://github.com/nativefier/nativefier/blob/master/API.md
# https://wiki.archlinux.org/title/Desktop_entries
# https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html

# Get app icon from Apple App Store
# wget -O "$TMPDIR/microsoft-to-do-512.jpg" "$(wget -qO- "https://itunes.apple.com/lookup?country=CN&id=1212616790" | jq -r .results[0].artworkUrl512)"
# vips scale "$TMPDIR/microsoft-to-do-512.jpg" "$TMPDIR/microsoft-to-do-256.jpg" --exp 0.5

VERSION=1.0

if [[ -f "$HOME/.nativefier/apps/microsoft-to-do/VERSION" ]]; then
    VERSION_INSTALLED="$(cat "$HOME/.nativefier/apps/microsoft-to-do/VERSION")"
else
    VERSION_INSTALLED="not_installed"
fi

# Microsoft To Do
if [[ "$VERSION_INSTALLED" != "$VERSION" ]]; then
    mkdir -p "$HOME/.nativefier/apps/microsoft-to-do"
    nativefier  https://to-do.live.com/ "$HOME/.nativefier/apps/microsoft-to-do" \
        --name "Microsoft To Do" \
        --icon "$SCRIPT_DIR/../icons/microsoft-to-do.png" \
        --platform linux \
        --arch x64 \
        --min-width 800 \
        --min-height 600 \
        --single-instance \
        --lang "zh_CN"
    echo "$VERSION" >"$HOME/.nativefier/apps/microsoft-to-do/VERSION"
fi

sudo cp -f "$SCRIPT_DIR/../icons/microsoft-to-do.png" "$HOME/.local/share/icons/hicolor/512x512/apps/microsoft-to-do.png"

# Desktop entry
cat <<EOF | sudo tee "$HOME/.local/share/applications/microsoft-to-do.desktop"
[Desktop Entry]
Type=Application
Name=Microsoft To Do
Exec=$HOME/.nativefier/apps/microsoft-to-do/MicrosoftToDo-linux-x64/MicrosoftToDo
Icon=microsoft-to-do
Categories=Office;
EOF

update-desktop-database "$HOME/.local/share/applications"
