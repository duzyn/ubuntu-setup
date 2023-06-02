#!/usr/bin/env bash

# Usage: install_appimage_apps jgraph/drawio-desktop draw.io
TMPDIR="$(mktemp -d)"

install_appimage_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED
    REPO_NAME=$1
    PACKAGE_NAME=$2
    VERSION_LATEST=$(wget -qO- --header "Authorization: $GITHUB_TOKEN" "https://api.github.com/repos/$REPO_NAME/releases/latest" | jq -r ".tag_name" | tr -d "v")

    if [[ -e "$HOME/.$PACKAGE_NAME/VERSION" ]]; then
        VERSION_INSTALLED=$(cat "$HOME/.$PACKAGE_NAME/VERSION")
        echo "$PACKAGE_NAME $VERSION_INSTALLED is installed."
    else
        VERSION_INSTALLED="not_installed"
    fi

    if [[ "$VERSION_INSTALLED" == "$VERSION_LATEST" ]]; then
        echo "$PACKAGE_NAME $VERSION_INSTALLED is lastest."
    else
        # Remove old version
        [[ -e "$HOME/.$PACKAGE_NAME/$PACKAGE_NAME.AppImage" ]] && rm -f "$HOME/.$PACKAGE_NAME/$PACKAGE_NAME.AppImage"
        sudo rm -f "$HOME/.local/share/applications/appimagekit-joplin.desktop"

        echo "Downloading $PACKAGE_NAME $VERSION_LATEST..."
        wget -O "$TMPDIR/$PACKAGE_NAME.AppImage" "$(wget -qO- --header "Authorization: $GITHUB_TOKEN" "https://api.github.com/repos/$REPO_NAME/releases/latest" | \
            jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g")"

        # Install new version
        [[ -d "$HOME/.$PACKAGE_NAME" ]] || mkdir -p "$HOME/.$PACKAGE_NAME"
        cp "$TMPDIR/$PACKAGE_NAME.AppImage" "$HOME/.$PACKAGE_NAME"
        chmod +x "$HOME/.$PACKAGE_NAME/$PACKAGE_NAME.AppImage"

        # Record version
        echo "$VERSION_LATEST" >"$HOME/.$PACKAGE_NAME/VERSION"
    fi
}

# install_appimage_apps localsend/localsend localsend
install_appimage_apps laurent22/joplin joplin
# Desktop entry
if [[ -e "$HOME/.local/share/icons/hicolor/512x512/apps/joplin.png" ]]; then
    echo "Icon is found."
else
    wget -O "$TMPDIR/joplin.png" https://joplinapp.org/images/Icon512.png
    sudo mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
    sudo mv "$TMPDIR/joplin.png" "$HOME/.local/share/icons/hicolor/512x512/apps/joplin.png"
fi

cat <<EOF > "$HOME/.local/share/applications/appimagekit-joplin.desktop"
[Desktop Entry]
Encoding=UTF-8
Name=Joplin
Comment=Joplin for Desktop
Exec=$HOME/.joplin/Joplin.AppImage %u
Icon=joplin
StartupWMClass=Joplin
Type=Application
Categories=Office;
MimeType=x-scheme-handler/joplin;
X-GNOME-SingleWindow=true
SingleMainWindow=true
EOF

update-desktop-database "$HOME/.local/share/applications"
