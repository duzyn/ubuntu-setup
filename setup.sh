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
: "${PROXY="false"}"
# set a github auth token (e.g a PAT ) in TOKEN to get a bigger rate limit
: "${TOKEN="false"}"
: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"
: "${GITHUB_PROXY:="https://ghproxy.com/"}"
: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node/"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"

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
[[ "$TOKEN" != "false" ]] && HEADER="--header 'Authorization: token ${TOKEN}'"

export DEBIAN_FRONTEND=noninteractive

if [[ "${PROXY}" == "false" ]]; then
    unset APT_MIRROR
    unset GITHUB_PROXY
    unset NVM_NODEJS_ORG_MIRROR
    unset NPM_REGISTRY_MIRROR
fi

# Can't connect to freedownloadmanager repo
[[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]] && \
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list

if [[ -f /etc/apt/sources.list ]]; then
    if [[ -n "$APT_MIRROR" ]]; then
        log "APT mirror is set to $APT_MIRROR."
        sudo sed -i \
            -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" \
            -e "s|security.ubuntu.com|$APT_MIRROR|g" \
            -e "s|http:|https:|g" \
            /etc/apt/sources.list
    else
        log "APT mirror is set to Ubuntu official."
        sudo sed -i \
            -e "s|//$APT_MIRROR|//archive.ubuntu.com|g" \
            -e "s|$APT_MIRROR|security.ubuntu.com|g" \
            -e "s|https:|http:|g" \
            /etc/apt/sources.list
    fi
fi

sudo apt-get update

log "# Insatlling BCM4360 wifi driver..."
sudo apt-get install -y dkms bcmwl-kernel-source

log "Installing some base packages..."
sudo apt-get install -y \
    apt-transport-https \
    aria2 \
    bat \
    build-essential \
    bzip2 \
    ca-certificates \
    coreutils \
    curl \
    fd-find \
    ffmpeg \
    file \
    gdebi \
    git \
    gpg \
    gzip \
    jq \
    libfuse2 \
    lsb-release \
    man-db \
    net-tools \
    p7zip \
    p7zip-full \
    patch \
    procps \
    proxychains4 \
    ripgrep \
    sed \
    software-properties-common \
    tar \
    unzip \
    wget \
    zip

# Fonts
log "Installing some fonts..."
sudo apt-get install -y \
    fonts-cascadia-code \
    fonts-emojione \
    fonts-firacode \
    fonts-noto-color-emoji \
    fonts-open-sans \
    fonts-roboto \
    fonts-ubuntu

# Locale
log "Installing Chinese language pack..."
sudo apt-get install -y \
    language-pack-gnome-zh-hans \
    language-pack-gnome-zh-hant \
    language-pack-zh-hans \
    language-pack-zh-hant

log "Installing Chinese fonts..."
sudo apt-get install -y \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    fonts-noto-cjk \
    fonts-noto-cjk-extra

log "Change locale to zh_CN."
sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN

# Google Chrome: https://google.cn/chrome
if ! dpkg -s "google-chrome-stable" &>/dev/null; then
    log "Installing Google Chrome..."
    wget -O "$TMPDIR/google-chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
else
    log "Google Chrome is installed."
fi

# Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if ! dpkg -s "microsoft-edge-stable" &>/dev/null; then
    log "Installing Microsoft Edge..."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" \
        /usr/share/keyrings/microsoft...gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
        https://packages.microsoft.com/repos/edge stable main" | \
            sudo tee /etc/apt/sources.list.d/microsoft-edge...list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
else
    log "Microsoft Edge is installed."
fi

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if ! dpkg -s "code" &>/dev/null; then
    log "Installing Visual Studio Code..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
        https://packages.microsoft.com/repos/vscode stable main" | \
            sudo tee /etc/apt/sources.list.d/vscode...list
    sudo apt-get update
    sudo apt-get install -y code
else
    log "Visual Studio Code is installed."
fi

# Onedriver: https://github.com/jstaf/onedriver
if ! dpkg -s "onedriver" &>/dev/null; then
    log "Installing Onedriver..."
    echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_20.04/ /' | \
        sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -O- https://download.opensuse.org/repositories/home:jstaf/xUbuntu_20.04/Release.key | \
        gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
    sudo apt-get install -y onedriver
else
    log "Onedriver is installed."
fi

# FSearch: https://github.com/cboxdoerfer/fsearch
if ! dpkg -s "fsearch" &>/dev/null; then
    log "Installing FSearch..."
    sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
else
    log "FSearch is installed."
fi

# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME=$1
    PACKAGE_NAME=$2
    PATTERN=$3
    API_URL=https://api.github.com/repos/${REPO_NAME}/releases/latest
    VERSION_LATEST=$(wget "$HEADER" -O- "${API_URL}" | \
        jq -r ".tag_name" | tr -d "v")

    if dpkg -s "${PACKAGE_NAME}" &>/dev/null; then
        VERSION_INSTALLED=$(dpkg -s "${PACKAGE_NAME}" | grep Version | cut -c 10- -)
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "${VERSION_LATEST}" == *"${VERSION_INSTALLED}"* || \
        "${VERSION_INSTALLED}" == *"${VERSION_LATEST}"* ]]; then
            log "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
    else
        log "Installing ${PACKAGE_NAME} ${VERSION_LATEST}..."
        wget -O "$TMPDIR/${PACKAGE_NAME}.deb" \
            "${GITHUB_PROXY}$(wget "$HEADER" -O- "${API_URL}" | \
                jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1)"
        sudo gdebi -n "$TMPDIR/${PACKAGE_NAME}.deb"
    fi
}

install_github_releases_apps vercel/hyper hyper amd64.deb
install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb
install_github_releases_apps jgraph/drawio-desktop draw.io .deb
install_github_releases_apps shiftkey/desktop github-desktop .deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb

# Installing 3rd party .AppImage apps from GitHub Releases
install_appimage_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED
    REPO_NAME=$1
    PACKAGE_NAME=$2
    API_URL=https://api.github.com/repos/${REPO_NAME}/releases/latest
    VERSION_LATEST=$(wget "$HEADER" -O- "${API_URL}" | \
        jq -r ".tag_name" | tr -d "v")

    if [[ -e "${HOME}/.${PACKAGE_NAME}/VERSION" ]]; then
        VERSION_INSTALLED=$(cat "${HOME}/.${PACKAGE_NAME}/VERSION")
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "${VERSION_LATEST}" == *"${VERSION_INSTALLED}"* || \
        "${VERSION_INSTALLED}" == *"${VERSION_LATEST}"* ]]; then
            log "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
    else
        # Remove old version
        [[ -e "${HOME}/Desktop/${PACKAGE_NAME}.AppImage" ]] && \
            rm -f "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"

        log "Installing ${PACKAGE_NAME} ${VERSION_LATEST}..."
        wget -O "$TMPDIR/${PACKAGE_NAME}.AppImage" \
            "${GITHUB_PROXY}$(wget "$HEADER" -O- "${API_URL}" | \
                jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1)"
        cp "$TMPDIR/${PACKAGE_NAME}.AppImage" "${HOME}/Desktop"
        chmod +x "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"

        # Record version
        [[ -d "${HOME}/.${PACKAGE_NAME}" ]] || mkdir "${HOME}/.${PACKAGE_NAME}"
        log "${VERSION_LATEST}" >"${HOME}/.${PACKAGE_NAME}/VERSION"
    fi
}

install_appimage_apps laurent22/joplin joplin
install_appimage_apps localsend/localsend localsend

# Sogou pinyin: https://shurufa.sogou.com/linux/guide
# should uninstall fcitx-ui-qimpanel first.
log "Installing fcitx config GUI..."
sudo apt-get install -y fcitx fcitx-config-gtk

log "fcitx-ui-qimpanel isn't compatible with Sogou Pinyin package, so uninstall it."
sudo apt-get remove -y fcitx-ui-qimpanel
sudo apt-get purge -y ibus

if ! dpkg -s "sogoupinyin" &>/dev/null; then
    log "Installing Sogou Pinyin dependencies..."
    sudo apt-get install -y \
        libgsettings-qt1 \
        libqt5qml5 \
        libqt5quick5 \
        libqt5quickwidgets5 \
        qml-module-qtquick2

    log "Installing Sogou Pinyin..."
    wget -O- https://shurufa.sogou.com/linux | \
        grep -E "https://ime-sec.*?amd64.deb" -o | \
            xargs wget -O "$TMPDIR/sogou-pinyin.deb"
    sudo gdebi -n "$TMPDIR/sogou-pinyin.deb"
else
    log "Sogou Pinyin is installed."
fi

# Free Download Manager
if ! dpkg -s "freedownloadmanager" &>/dev/null; then
    log "Installing Free Download Manager..."
    wget -O "$TMPDIR/freedownloadmanager.deb" \
        https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
else
    log "Free Download Manager is installed."
fi

# Greenfish Icon Editor Pro
if ! dpkg -s "gfie" &>/dev/null; then
    log "Installing Greenfish Icon Editor Pro..."
    wget -O gfie.deb http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n gfie.deb
else
    log "Greenfish Icon Editor Pro is installed."
fi

# Just: https://github.com/casey/just
if ! dpkg -s "gfie" &>/dev/null; then
    log "Installing Just..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring...gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] \
        https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr...list
    sudo apt update
    sudo apt install -y just
else
    log "Just is installed."
fi

# Node, npm, nvm
# https://github.com/nvm-sh/nvm
log "Installing nvm..."
wget -O- "${GITHUB_PROXY}https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | \
    sed -e "s|https://raw.githubusercontent.com|${GITHUB_PROXY}https://raw.githubusercontent.com|g" \
        -e "s|https://github.com|${GITHUB_PROXY}https://github.com|g" | \
    bash

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

log "Installing latest version LTS nodejs..."
nvm install --lts

if [[ -n "${NVM_NODEJS_ORG_MIRROR}" ]]; then
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" "${HOME}/.bashrc"; then
        log "export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" >>"${HOME}/.bashrc"
        log "NVM_NODEJS_ORG_MIRROR is set to ${NVM_NODEJS_ORG_MIRROR}"
    fi
fi

touch "${HOME}/.npmrc"
if [[ -n "${NPM_REGISTRY_MIRROR}" ]]; then
    if ! grep -q "registry" "${HOME}/.npmrc"; then
        log "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
        log "NPM_REGISTRY_MIRROR is set to ${NPM_REGISTRY_MIRROR}"
    fi
fi

log "Updating npm..."
npm update -g

# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if ! dpkg -s "miktex" &>/dev/null; then
    log "Installing MiKTeX..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install -y miktex
else
    log "MiKTeX is installed."
fi

# Finish the setup.
# Before you can use MiKTeX, you have to finish the setup.
# You can use MiKTeX Console or, if you prefer the command line, `miktexsetup`.

# finish with a private (for you only) TeX installation. Executables like
# lualatex will be installed in ~/bin.
miktexsetup finish

# You also may want to enable automatic package installation:
initexmf --set-config-value \[MPM\]AutoInstall=1

# If you don't use mirror, you can comment this.
initexmf --set-config-value \
    \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/

log "Installing some extra apps..."
sudo apt-get install -y \
    android-sdk-platform-tools \
    audacity \
    calibre \
    copyq \
    digikam \
    filezilla \
    flameshot \
    freecad \
    ghostscript \
    gimp \
    handbrake \
    inkscape \
    mupdf \
    mupdf-tools \
    neofetch \
    obs-studio \
    openjdk-16-jdk \
    openshot \
    openvpn \
    scrcpy \
    scribus \
    vlc

# Some Windows apps
# https://www.ubuntukylin.com/applications
# Wine
if ! dpkg -s "ukylin-wine" &>/dev/null; then
    log "Installing Wine..."
    wget -O "$TMPDIR/ukylin-wine.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wine.deb"
else
    log "Wine is installed."
fi

# WeChat
if ! dpkg -s "ukylin-wechat" &>/dev/null; then
    log "Installing WeChat..."
    wget -O "$TMPDIR/ukylin-wechat.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wechat.deb"
else
    log "WeChat is installed."
fi

# WeChat Work
if ! dpkg -s "ukylin-wxwork" &>/dev/null; then
    log "Installing WeChat Work..."
    wget -O "$TMPDIR/ukylin-wxwork.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-wxwork.deb"
else
    log "WeChat Work is installed."
fi

# Tencent Meeting
if ! dpkg -s "ukylin-tencentmeeting" &>/dev/null; then
    log "Installing Tencent Meeting..."
    wget -O "$TMPDIR/ukylin-tencentmeeting.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64...deb
    sudo gdebi -n "$TMPDIR/ukylin-tencentmeeting.deb"
else
    log "Tencent Meeting is installed..."
fi

# Photoshop CS6
if ! dpkg -s "ukylin-ps6" &>/dev/null; then
    log "Installing Photoshop CS6..."
    wget -O "$TMPDIR/ukylin-ps6.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
    sudo gdebi -n "$TMPDIR/ukylin-ps6.deb"
else
    log "Photoshop CS6 is installed."
fi

# Some Chinese apps.
# Xunlei
if ! dpkg -s "com.xunlei.download" &>/dev/null; then
    log "Installing Xunlei..."
    wget -O "$TMPDIR/xunlei.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
    sudo gdebi -n "$TMPDIR/xunlei.deb"
else
    log "Xunlei is installed."
fi

# WPS
if ! dpkg -s "wps-office" &>/dev/null; then
    log "Installing WPS..."
    wget -O "$TMPDIR/wps-office.deb" \
        https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
    sudo gdebi -n "$TMPDIR/wps-office.deb"
else
    log "WPS is installed."
fi

if ! dpkg -s "wps-fonts" &>/dev/null; then
    log "Installing symbol fonts..."
    sudo add-apt-repository ppa:atareao/atareao 
    sudo apt-get update
    sudo apt-get install -y wps-fonts
else
    log "WPS symbol fonts are installed."
fi

# Tor Browser
TOR_BROWSER_LATEST_VERSION=$(wget "$HEADER" \
    -O- "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" | \
        jq -r ".tag_name" | sed "s/.*-//g")

if [[ -e "${HOME}/.tor-browser/VERSION" ]]; then
    TOR_BROWSER_INSTALLED_VERSION=$(cat "${HOME}/.tor-browser/VERSION")
else
    TOR_BROWSER_INSTALLED_VERSION=not_installed
fi

if [[ "${TOR_BROWSER_INSTALLED_VERSION}" != "${TOR_BROWSER_LATEST_VERSION}" ]]; then
    # Remove old version.
    if [[ -d "${HOME}/tor-browser" ]]; then
        "${HOME}/tor-browser/Browser/start-tor-browser" --unregister-app
        rm -r "${HOME}/tor-browser"
    fi

    log "Installing Tor Browser..."
    wget -O "$TMPDIR/tor-browser.tar.xz" \
        "${GITHUB_PROXY}https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${TOR_BROWSER_LATEST_VERSION}/tor-browser-linux64-${TOR_BROWSER_LATEST_VERSION}_ALL.tar.xz"

    [[ -d "$TMPDIR/tor-browser-tmp" ]] && rm -r "$TMPDIR/tor-browser-tmp"
    7z x -o"$TMPDIR/tor-browser-tmp" "$TMPDIR/tor-browser.tar.xz"
    7z x -o"$TMPDIR/tor-browser-tmp" "$TMPDIR/tor-browser-tmp/*.tar"
    cp -r "$TMPDIR/tor-browser-tmp/tor-browser" "${HOME}/"

    chmod +x "${HOME}/tor-browser/Browser/start-tor-browser"
    "${HOME}/tor-browser/Browser/start-tor-browser" --register-app

    [[ -d "${HOME}/.tor-browser" ]] || mkdir "${HOME}/.tor-browser"
    log "${TOR_BROWSER_LATEST_VERSION}" >"${HOME}/.tor-browser/VERSION"
else
    log "Tor Browser is installed."
fi

log "Uninstall unnecessary apps."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Check installed apps' update
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
VTOY_API_URL=https://api.github.com/repos/ventoy/vtoyboot/releases/latest
VTOY_VERSION=$(wget "$HEADER" \
    -O- "${VTOY_API_URL}" | jq -r ".tag_name" | tr -d "v")

log "Downloading vtoyboot ${VTOY_VERSION}..."
wget -O "$TMPDIR/vtoyboot.iso" \
    "${GITHUB_PROXY}$(wget "$HEADER" -O- "${VTOY_API_URL}" | \
        jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
[[ -d "$TMPDIR/vtoyboot-tmp" ]] && rm -r "$TMPDIR/vtoyboot-tmp"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot.iso"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar.gz"
7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar"

log "Running vtoyboot..."
cd "$TMPDIR/vtoyboot-tmp/vtoyboot-${VTOY_VERSION}" || exit
sudo bash "./vtoyboot.sh"

die "Completed! You can poweroff vbox, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder." 0

# TODO freemind, axure,
