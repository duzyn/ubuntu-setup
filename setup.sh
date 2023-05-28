#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Inspired by https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
: "${DEBUG="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace
#  Configurations
: "${LOCALE:="zh_CN"}"
: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"

[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1

function log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
    local msg=$1
    local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    log "$msg"
    exit "$code"
}

TMPDIR="$(mktemp -d)"

export DEBIAN_FRONTEND=noninteractive

# Can't connect to freedownloadmanager repo, so remove it.
[[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]] && sudo rm /etc/apt/sources.list.d/freedownloadmanager.list

if [[ "$APT_MIRROR" == "false" ]]; then
    log "Using Ubuntu official repo..."
else
    if [[ -f /etc/apt/sources.list ]]; then
        log "APT mirror is set to $APT_MIRROR."
        sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
            -e "s|http:|https:|g" /etc/apt/sources.list
        sudo apt-get update
    else
        log "There's no sources.list."
    fi
fi


log "Insatlling BCM4360 wifi driver..."
sudo apt-get install -y dkms bcmwl-kernel-source

log "Installing some base packages..."
sudo apt-get install -y apt-transport-https aria2 bat build-essential bzip2 ca-certificates coreutils curl \
    fd-find ffmpeg file gcc g++ gdebi gpg gzip jq libfuse2 lsb-release make man-db net-tools ntp \
    p7zip p7zip-full patch procps proxychains4 ripgrep sed software-properties-common tar unzip wget zip

# Git latest version
if [[ -x "$(command -v git)" ]]; then
    log "Git is installed."
else
    log "Installing latest Git..."
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
    sudo apt install -y git
fi

# Google Chrome: https://google.cn/chrome
if [[ -x "$(command -v google-chrome)" ]]; then
    log "Google Chrome is installed."
else
    log "Installing Google Chrome..."
    wget -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
fi

# Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if [[ -x "$(command -v microsoft-edge)" ]]; then
    log "Microsoft Edge is installed."
else
    log "Installing Microsoft Edge..."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | \
        sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
fi

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if [[ -x "$(command -v code)" ]]; then
    log "Visual Studio Code is installed."
else
    log "Installing Visual Studio Code..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
fi

# Flatpak: https://flatpak.org/setup/Ubuntu
if [[ -x "$(command -v flatpak)" ]]; then
    log "Flatpak is installed."
else
    log "Installing Flatpak..."
    sudo apt-get install flatpak
    # sudo apt install gnome-software-plugin-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    die "To complete setup, restart your system. run: sudo shutdown -r now" 0
fi

flatpak install -y flathub io.github.shiftey.Desktop
flatpak install -y flathub com.jgraph.drawio.desktop
flatpak install -y flathub io.dbeaver.DBeaverCommunity
flatpak install -y flathub net.cozic.joplin_desktop
flatpak install -y flathub net.xmind.XMind
# flatpak install -y flathub org.freedownloadmanager.Manager
flatpak install -y flathub org.localsend.localsend_app

# Fonts
log "Installing some fonts..."
sudo apt-get install -y fonts-cascadia-code fonts-emojione fonts-firacode fonts-noto-color-emoji fonts-open-sans fonts-roboto fonts-ubuntu

# Locale
if [[ $LOCALE == "zh_CN" ]]; then
    log "Installing Chinese language pack..."
    sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans

    log "Installing Chinese fonts..."
    sudo apt-get install -y fonts-arphic-ukai fonts-arphic-uming fonts-noto-cjk fonts-noto-cjk-extra
fi

log "Changing locale to $LOCALE..."
sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"


# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
log "Setting user dirs name..."
cd "$HOME" && mkdir -p Desktop Documents Download Music Pictures Publicshare Templates Videos
xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
xdg-user-dirs-update --set DOWNLOAD "$HOME/Download"
xdg-user-dirs-update --set MUSIC "$HOME/Music"
xdg-user-dirs-update --set PICTURES "$HOME/Pictures"
xdg-user-dirs-update --set PUBLICSHARE "$HOME/Publicshare"
xdg-user-dirs-update --set TEMPLATES "$HOME/Templates"
xdg-user-dirs-update --set VIDEOS "$HOME/Videos"

# Albert: https://github.com/albertlauncher/albert
[[ -n "$(command -v albert)" ]] || {
    log "Installing Albert..."
    echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    wget -qO- "https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
    sudo apt update
    sudo apt install -y albert
}

# Onedriver: https://github.com/jstaf/onedriver
[[ -n "$(command -v onedriver)" ]] || {
    log "Installing Onedriver..."
    echo "deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
    sudo apt-get install -y onedriver
}

# Greenfish Icon Editor Pro
[[ -n "$(command -v gfie)" ]] || {
    log "Installing Greenfish Icon Editor Pro..."
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
}

# Just: https://github.com/casey/just
[[ -n "$(command -v just)" ]] || {
    log "Installing Just..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | 、
        sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
    sudo apt update
    sudo apt install -y just
}

# FSearch: https://github.com/cboxdoerfer/fsearch
[[ -n "$(command -v fsearch)" ]] || {
    log "Installing FSearch..."
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
}

# Free Download Manager
[[ -n "$(dpkg -s freedownloadmanager)" ]] || {
    log "Installing Free Download Manager..."
    wget -O "$TPMDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
}

# Node, npm
log "Installing nvm..."
if eval "curl -sk https://raw.githubusercontent.com" >> /dev/null 2>&1; then
    log "Connected to GitHub!"
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | bash
elif eval "curl -sk https://ghproxy.com" >> /dev/null 2>&1; then
    log "Connected to GitHub Proxy!"
    wget -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | \
        sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/raw.githubusercontent.com|g" \
            -e "s|https://github.com|https://ghproxy.com/github.com|g" | bash
else
    die "Failed! No internet connection available."
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

log "Installing latest version LTS nodejs..."
nvm install --lts

if [[ "$NVM_NODEJS_ORG_MIRROR" == "false" ]]; then
    log "Using Node official repo..."
else
    if grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
        log "NVM_NODEJS_ORG_MIRROR is set."
    else
        echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
        log "NVM_NODEJS_ORG_MIRROR is set to $NVM_NODEJS_ORG_MIRROR."
    fi
fi

touch "$HOME/.npmrc"
if [[ "$NPM_REGISTRY_MIRROR" == "false" ]]; then
    log "Using npm official repo..."
else
    if grep -q "registry=" "$HOME/.npmrc"; then
        log "NPM_REGISTRY_MIRROR is set."
    else
        echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
        log "NPM_REGISTRY_MIRROR is set to $NPM_REGISTRY_MIRROR."
    fi
fi

log "Updating npm..."
npm update -g

# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME=$1
    PACKAGE_NAME=$2
    PATTERN=$3
    API_URL=https://api.github.com/repos/$REPO_NAME/releases/latest
    VERSION_LATEST=$(wget -O- "$API_URL" | jq -r ".tag_name" | tr -d "v")

    if dpkg -s "$PACKAGE_NAME" &>/dev/null; then
        VERSION_INSTALLED=$(dpkg -s "$PACKAGE_NAME" | grep Version | cut -c 10- -)
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]]; then
            log "$PACKAGE_NAME $VERSION_LATEST is lastest."
    else
        log "Installing $PACKAGE_NAME $VERSION_LATEST..."
        wget -O "$TMPDIR/$PACKAGE_NAME.deb" \
            "$(wget -O- "$API_URL" | jq -r ".assets[].browser_download_url" | \
                grep "${PATTERN}" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g")"
        sudo gdebi -n "$TMPDIR/$PACKAGE_NAME.deb"
    fi
}

install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb
# install_github_releases_apps vercel/hyper hyper amd64.deb
# install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
# install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb
# install_github_releases_apps jgraph/drawio-desktop draw.io .deb
# install_github_releases_apps shiftkey/desktop github-desktop .deb


# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
[[ -n "$(command -v miktex)" ]] || {
    log "Installing MiKTeX..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb http://miktex.org/download/ubuntu $(lsb_release -cs) universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install -y miktex
}

# Finish the setup.
# Before you can use MiKTeX, you have to finish the setup.
# You can use MiKTeX Console or, if you prefer the command line, `miktexsetup`.
# https://docs.miktex.org/manual/miktexsetup.html

# finish with a private (for you only) TeX installation. Executables like
# lualatex will be installed in ~/bin.
miktexsetup finish

# You also may want to enable automatic package installation:
initexmf --set-config-value \[MPM\]AutoInstall=1

# If you don't use mirror, you can comment this.
initexmf --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/

log "Installing some extra apps..."
sudo apt-get install -y android-sdk-platform-tools audacity calibre digikam filezilla flameshot freecad \
    ghostscript gimp handbrake imagemagick inkscape mupdf mupdf-tools neofetch obs-studio openjdk-16-jdk openshot openvpn \
    pdfarranger plank scrcpy scribus vlc xfce4-appmenu-plugin


# Theme
# WM: Materia: https://github.com/nana-4/materia-theme
# Icons: Papirus: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
[[ -n "$(dpkg -s materia-gtk-theme)" ]] || {
    sudo apt-get install -y materia-gtk-theme
}

[[ -n "$(dpkg -s papirus-icon-theme)" ]] || {
    log "Installing apirus-icon-theme..."
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt-get update
    sudo apt-get install -y papirus-icon-theme
}

# For GTK3
gsettings set org.gnome.desktop.interface gtk-theme "Materia"
gsettings set org.gnome.desktop.wm.preferences theme "Materia"
gsettings set org.gnome.desktop.interface icon-theme "Papirus"
# For GTK2
xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
xfconf-query -c xfwm4 -p /general/theme -s "Materia"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"

xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Noto Sans Mono CJK SC 9"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"

# Hardcode-Tray: https://github.com/bilelmoussaoui/Hardcode-Tray
[[ -n "$(dpkg -s hardcode-tray)" ]] || {
    sudo add-apt-repository -y ppa:papirus/hardcode-tray
    sudo apt update
    sudo apt install -y hardcode-tray
}

# Some Windows apps on Ubuntu Kylin
# https://www.ubuntukylin.com/applications
[[ -f /etc/apt/sources.list.d/ubuntukylin.list ]] || {
    log "Installing Ubuntu Kylin apps..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56583E647FFA7DE7
    echo "deb http://archive.ubuntukylin.com/ubuntukylin $(lsb_release -cs)-partner main" | sudo tee /etc/apt/sources.list.d/ubuntukylin.list
    sudo apt-get update
    sudo apt-get install -y sogoupinyin ukylin-wine ukylin-wechat ukylin-wxwork ukylin-tencentmeeting ukylin-ps6 com.xunlei.download wps-office
}
# Fix ADM  error when launch PS6
[[ -f "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" ]] && {
    mv "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" \
        "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl.backup"
}


[[ -n "$(dpkg -s wps-fonts)" ]] || {
    log "Installing symbol fonts..."
    sudo add-apt-repository ppa:atareao/atareao 
    sudo apt-get update
    sudo apt-get install -y wps-fonts
}


log "Uninstall unnecessary apps."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Check installed apps' update
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
VTOY_LATEST_VERSION=$(wget -O- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")
VTOY_INSTALLED_VERSION=not_installed
[[ -e "$HOME/.vtoyboot/VERSION" ]] && VTOY_INSTALLED_VERSION=$(cat "$HOME/.vtoyboot/VERSION")

[[ "$VTOY_INSTALLED_VERSION" != "$VTOY_LATEST_VERSION" ]] && {
    # Remove old version.
    [[ -d "$HOME/vtoyboot" ]] && {
        rm -r "$HOME/vtoyboot"
    }

    # Install new version.
    log "Downloading vtoyboot $VTOY_LATEST_VERSION..."
    wget -O "$TMPDIR/vtoyboot.iso" "$(wget -O- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
    [[ -d "$TMPDIR/vtoyboot-tmp" ]] && rm -r "$TMPDIR/vtoyboot-tmp"
    7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot.iso"
    7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar.gz"
    7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar"
    cp -r "$TMPDIR/vtoyboot-tmp/vtoyboot-$VTOY_LATEST_VERSION" "$HOME/vtoyboot"

    # Record version
    [[ -d "$HOME/.vtoyboot" ]] || mkdir "$HOME/.vtoyboot"
    echo "$VTOY_LATEST_VERSION" >"$HOME/.vtoyboot/VERSION"
}

log "Running vtoyboot..."
cd "$HOME/vtoyboot" || die "No vtoyboot folder."
sudo bash "./vtoyboot.sh"

die "Completed! You can poweroff vbox, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder." 0
