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
: "${LOCALE:="en_US"}"
: "${APT_MIRROR:="archive.ubuntu.com"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmjs.org"}"

# SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

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

[[ -f /etc/apt/sources.list ]] && {
    log "APT mirror is set to $APT_MIRROR."
    sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" -e "s|http:|https:|g" /etc/apt/sources.list
}

sudo apt-get update

log "Insatlling BCM4360 wifi driver..."
sudo apt-get install -y dkms bcmwl-kernel-source

log "Installing some base packages..."
sudo apt-get install -y apt-transport-https aria2 bat build-essential bzip2 ca-certificates coreutils curl fd-find ffmpeg file gdebi git gpg gzip jq libfuse2 lsb-release man-db net-tools p7zip p7zip-full patch procps proxychains4 ripgrep sed software-properties-common tar unzip wget zip

# Google Chrome: https://google.cn/chrome
[[ -x "$(command -v google-chrome)" ]] || {
    log "Installing Google Chrome..."
    wget -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
}

# Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
[[ -x "$(command -v microsoft-edge)" ]] || {
    log "Installing Microsoft Edge..."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
}

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
[[ -x "$(command -v code)" ]] || {
    log "Installing Visual Studio Code..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
}

# Flatpak: https://flatpak.org/setup/Ubuntu
[[ -x "$(command -v flatpak)" ]] || {
    log "Installing Flatpak..."
    sudo apt-get install flatpak
    # sudo apt install gnome-software-plugin-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    die "To complete setup, restart your system. run sudo shutdown -r now" 0
}

flatpak install -y flathub com.jgraph.drawio.desktop
flatpak install -y flathub io.dbeaver.DBeaverCommunity
flatpak install -y flathub net.cozic.joplin_desktop
flatpak install -y flathub net.xmind.XMind
flatpak install -y flathub org.freedownloadmanager.Manager
flatpak install -y flathub org.localsend.localsend_app

# Fonts
log "Installing some fonts..."
sudo apt-get install -y fonts-cascadia-code fonts-emojione fonts-firacode fonts-noto-color-emoji fonts-open-sans fonts-roboto fonts-ubuntu

# Locale
[[ $LOCALE == "zh_CN" ]] && {
    log "Installing Chinese language pack..."
    sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans

    log "Installing Chinese fonts..."
    sudo apt-get install -y fonts-arphic-ukai fonts-arphic-uming fonts-noto-cjk fonts-noto-cjk-extra
}

log "Change locale to $LOCALE."
sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"


# Onedriver: https://github.com/jstaf/onedriver
[[ -n "$(command -v onedriver)" ]] || {
    log "Installing Onedriver..."
    echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- https://download.opensuse.org/repositories/home:jstaf/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
    sudo apt-get install -y onedriver
}

# Greenfish Icon Editor Pro
[[ -n "$(command -v gfie)" ]] || {
    log "Installing Greenfish Icon Editor Pro..."
    wget -qO "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
}

# Just: https://github.com/casey/just
[[ -n "$(command -v just)" ]] || {
    log "Installing Just..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
    sudo apt update
    sudo apt install -y just
}

# FSearch: https://github.com/cboxdoerfer/fsearch
[[ -n "$(command -v fsearch)" ]] || {
    log "Installing FSearch..."
    sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
}

# Node, npm
# https://github.com/nodesource/distributions/blob/master/README.md#debinstall
wget -qO- https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs

touch "${HOME}/.npmrc"
grep -q "registry=" "${HOME}/.npmrc" || {
    echo "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
    log "NPM_REGISTRY_MIRROR is set to ${NPM_REGISTRY_MIRROR}"
}

log "Updating npm..."
npm update -g

# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
[[ -n "$(command -v miktex)" ]] || {
    log "Installing MiKTeX..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
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
sudo apt-get install -y android-sdk-platform-tools audacity calibre copyq digikam filezilla flameshot freecad ghostscript gimp handbrake inkscape mupdf mupdf-tools neofetch obs-studio openjdk-16-jdk openshot openvpn pdfarranger scrcpy scribus vlc

# Some Windows apps
# https://www.ubuntukylin.com/applications
# Wine
[[ -n "$(command -v ukylin-wine)" ]] || {
    log "Installing Wine..."
    wget -qO "$TMPDIR/ukylin-wine.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wine.deb"
}

# WeChat
[[ -n "$(dpkg -s ukylin-wechat)" ]] || {
    log "Installing WeChat..."
    wget -qO "$TMPDIR/ukylin-wechat.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wechat.deb"
}

# WeChat Work
[[ -n "$(dpkg -s ukylin-wxwork)" ]] || {
    log "Installing WeChat Work..."
    wget -qO "$TMPDIR/ukylin-wxwork.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wxwork.deb"
}

# Tencent Meeting
[[ -n "$(dpkg -s ukylin-tencentmeeting)" ]] || {
    log "Installing Tencent Meeting..."
    wget -qO "$TMPDIR/ukylin-tencentmeeting.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-tencentmeeting.deb"
}

# Photoshop CS6
# Rename or delete <PS6 path>/Required/Plug-Ins/ADM/ADMPlugin.apl
[[ -n "$(dpkg -s ukylin-ps6)" ]] || {
    log "Installing Photoshop CS6..."
    wget -qO "$TMPDIR/ukylin-ps6.deb" https://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-ps6.deb"
}

# Some Chinese apps.
# Xunlei
[[ -n "$(dpkg -s com.xunlei.download)" ]] || {
    log "Installing Xunlei..."
    wget -qO "$TMPDIR/xunlei.deb" https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
    sudo gdebi -n "$TMPDIR/xunlei.deb"
}

# WPS
[[ -n "$(dpkg -s wps-office)" ]] || {
    log "Installing WPS..."
    wget -qO "$TMPDIR/wps-office.deb" https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
    sudo gdebi -n "$TMPDIR/wps-office.deb"
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
VTOY_VERSION=$(wget -qO- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")

log "Downloading vtoyboot ${VTOY_VERSION}..."
wget -qO "$TMPDIR/vtoyboot.iso" "$(wget -qO- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
[[ -d "$TMPDIR/vtoyboot-tmp" ]] && rm -r "$TMPDIR/vtoyboot-tmp"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot.iso"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar.gz"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar"

log "Running vtoyboot..."
cd "$TMPDIR/vtoyboot-tmp/vtoyboot-${VTOY_VERSION}" || exit
sudo bash "./vtoyboot.sh"

die "Completed! You can poweroff vbox, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder." 0
