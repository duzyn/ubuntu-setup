#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive


# https://github.com/nativefier/nativefier/blob/master/API.md
# https://wiki.archlinux.org/title/Desktop_entries
# https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html

# Get app icon from Apple App Store
# wget -O "$TMPDIR/microsoft-to-do-512.jpg" "$(wget -qO- "https://itunes.apple.com/lookup?country=CN&id=1212616790" | jq -r .results[0].artworkUrl512)"
# vips scale "$TMPDIR/microsoft-to-do-512.jpg" "$TMPDIR/microsoft-to-do-256.jpg" --exp 0.5

# Microsoft To Do
[[ -d "$HOME/.nativefier/apps/" ]] || mkdir -p "$HOME/.nativefier/apps/"
nativefier  https://to-do.live.com/ "$HOME/.nativefier/apps/" \
    --name "Microsoft To Do" \
    --icon "$SCRIPT_DIR/icons/microsoft-to-do-256.png" \
    --platform linux \
    --arch x64 \
    --min-width 800 \
    --min-height 600 \
    --portable \
    --single-instance \
    --tray \
    --lang "zh_CN"

sudo cp -f "$SCRIPT_DIR/icons/microsoft-to-do-256.png" "$HOME/.local/share/icons/hicolor/256x256/apps/"

# Desktop entry
cat <<EOF >"$TMPDIR/microsoft-to-do.desktop"
[Desktop Entry]
Type=Application
Name=Microsoft To Do
Exec=$HOME/.nativefier/apps/MicrosoftToDo-linux-x64/MicrosoftToDo
Icon=$HOME/.local/share/icons/hicolor/256x256/apps/microsoft-to-do-256.png
Categories=Office;
EOF

desktop-file-install --dir="$HOME/.local/share/applications" "$TMPDIR/microsoft-to-do.desktop"
update-desktop-database "$HOME/.local/share/applications"
