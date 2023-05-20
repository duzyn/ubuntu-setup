#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Author: David Peng
# Date: 2023-05-19

# Inspired by https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail


# Environment Variables
# UBUNTU_SETUP_DEBUG=on
# UBUNTU_SETUP_PROXY=on
# UBUNTU_SETUP_LOCALE=zh_CN
# UBUNTU_SETUP_TOKEN={GitHub Personal Token}

if [[ -n "${UBUNTU_SETUP_DEBUG}" ]]; then
    # Turn on traces, useful while debugging but commented out by default
    set -o xtrace
fi

export DEBIAN_FRONTEND=noninteractive

if [[ -n "${UBUNTU_SETUP_PROXY}" ]]; then
    APT_MIRROR=mirrors.ustc.edu.cn/ubuntu
    GITHUB_PROXY=https://ghproxy.com/
    NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
    NPM_REGISTRY_MIRROR=https://registry.npmmirror.com
else
    unset APT_MIRROR
    unset GITHUB_PROXY
    unset NVM_NODEJS_ORG_MIRROR
    unset NPM_REGISTRY_MIRROR
fi

# set a github auth token (e.g a PAT ) in TOKEN to get a bigger rate limit
if [[ -n "${UBUNTU_SETUP_TOKEN}" ]]; then
    export HEADERPARAM="--header"
    export HEADERAUTH="Authorization: token ${UBUNTU_SETUP_TOKEN}"
else
    unset HEADERPARAM
    unset HEADERAUTH
fi

# Can't connect to freedownloadmanager repo
[[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]] &&
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list

if [[ -n "${APT_MIRROR}" ]]; then
    echo "APT mirror is set to ${APT_MIRROR}."

    # https://mirrors.ustc.edu.cn/help/ubuntu.html
    sudo sed -i "s@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g" /etc/apt/sources.list
    sudo sed -i "s@security.ubuntu.com@mirrors.ustc.edu.cn@g" /etc/apt/sources.list
    sudo sed -i "s@http:@https:@g" /etc/apt/sources.list
    sudo apt-get update
else
    sudo sed -i "s@//mirrors.ustc.edu.cn@//archive.ubuntu.com@g" /etc/apt/sources.list
    sudo sed -i "s@mirrors.ustc.edu.cn@security.ubuntu.com@g" /etc/apt/sources.list
    sudo sed -i "s@https:@http:@g" /etc/apt/sources.list
    sudo apt-get update
fi

echo "Install some base packages."
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    aria2 \
    build-essential \
    bzip2 \
    ca-certificates \
    coreutils \
    curl \
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
    p7zip \
    p7zip-full \
    patch \
    procps \
    proxychains4 \
    sed \
    software-properties-common \
    tar \
    unzip \
    wget \
    zip

if [[ "${UBUNTU_SETUP_LOCALE}" == "zh_CN" ]]; then
    echo "Install Chinese language pack."
    sudo apt-get update
    sudo apt-get install -y \
        language-pack-gnome-zh-hans \
        language-pack-gnome-zh-hant \
        language-pack-zh-hans \
        language-pack-zh-hant

    echo "Install Chinese fonts."
    sudo apt-get update
    sudo apt-get install -y \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-noto-cjk \
        fonts-noto-cjk-extra
fi

if [[ -n "${UBUNTU_SETUP_LOCALE}" ]]; then
    echo "Change locale to ${UBUNTU_SETUP_LOCALE}."
    sudo update-locale LANG=${UBUNTU_SETUP_LOCALE}.UTF-8 LANGUAGE=${UBUNTU_SETUP_LOCALE}
fi

# Google Chrome
# https://google.cn/chrome
if ! dpkg -s "google-chrome-stable" &>/dev/null; then
    echo "Install Google Chrome."
    wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n /tmp/google-chrome.deb
else
    echo "Google Chrome is installed."
fi

# Microsoft Edge
# https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if ! dpkg -s "microsoft-edge-stable" &>/dev/null; then
    echo "Install Microsoft Edge."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
else
    echo "Microsoft Edge is installed."
fi

# Visual Studio Code
# https://code.visualstudio.com/docs/setup/linux
if ! dpkg -s "code" &>/dev/null; then
    echo "Install Visual Studio Code."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
else
    echo "Visual Studio Code is installed."
fi

# Onedriver
# https://github.com/jstaf/onedriver
if ! dpkg -s "onedriver" &>/dev/null; then
    echo "Install Onedriver."
    echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -O- https://download.opensuse.org/repositories/home:jstaf/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
    sudo apt-get install -y onedriver
else
    echo "Onedriver is installed."
fi

# FSearch
# https://github.com/cboxdoerfer/fsearch
if ! dpkg -s "fsearch" &>/dev/null; then
    echo "Install FSearch."
    sudo add-apt-repository ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
else
    echo "FSearch is installed."
fi

# Install 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME=$1
    PACKAGE_NAME=$2
    PATTERN=$3
    API_URL=https://api.github.com/repos/${REPO_NAME}/releases/latest
    VERSION_LATEST=$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${API_URL}" | jq -r ".tag_name" | tr -d "v")

    if dpkg -s "${PACKAGE_NAME}" &>/dev/null; then
        VERSION_INSTALLED=$(dpkg -s "${PACKAGE_NAME}" | grep Version | cut -c 10- -)
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "${VERSION_LATEST}" == *"${VERSION_INSTALLED}"* || "${VERSION_INSTALLED}" == *"${VERSION_LATEST}"* ]]; then
        echo "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
    else
        echo "Install ${PACKAGE_NAME} ${VERSION_LATEST}."
        wget -O "/tmp/${PACKAGE_NAME}.deb" "${GITHUB_PROXY}$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${API_URL}" | jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1)"
        sudo gdebi -n "/tmp/${PACKAGE_NAME}.deb"
    fi
}

install_github_releases_apps vercel/hyper hyper amd64.deb
install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb
install_github_releases_apps jgraph/drawio-desktop draw.io .deb
install_github_releases_apps shiftkey/desktop github-desktop .deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb

# Install 3rd party .AppImage apps from GitHub Releases
install_appimage_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED
    REPO_NAME=$1
    PACKAGE_NAME=$2
    API_URL=https://api.github.com/repos/${REPO_NAME}/releases/latest
    VERSION_LATEST=$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${API_URL}" | jq -r ".tag_name" | tr -d "v")

    if [[ -e "${HOME}/.${PACKAGE_NAME}/VERSION" ]]; then
        VERSION_INSTALLED=$(cat "${HOME}/.${PACKAGE_NAME}/VERSION")
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "${VERSION_LATEST}" == *"${VERSION_INSTALLED}"* || "${VERSION_INSTALLED}" == *"${VERSION_LATEST}"* ]]; then
        echo "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
    else
        # Remove old version
        [[ -e "${HOME}/Desktop/${PACKAGE_NAME}.AppImage" ]] && rm -f "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"

        echo "Install ${PACKAGE_NAME} ${VERSION_LATEST}."
        wget -O "/tmp/${PACKAGE_NAME}.AppImage" "${GITHUB_PROXY}$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${API_URL}" | jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1)"
        cp "/tmp/${PACKAGE_NAME}.AppImage" "${HOME}/Desktop"
        chmod +x "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"

        # Record version
        [[ -d "${HOME}/.${PACKAGE_NAME}" ]] || mkdir "${HOME}/.${PACKAGE_NAME}"
        echo "${VERSION_LATEST}" >"${HOME}/.${PACKAGE_NAME}/VERSION"
    fi
}

install_appimage_apps laurent22/joplin joplin
install_appimage_apps localsend/localsend localsend

# Sogou pinyin
# https://shurufa.sogou.com/linux/guide
# should uninstall fcitx-ui-qimpanel first.
echo "Install fcitx config GUI."
sudo apt-get install -y fcitx fcitx-config-gtk

echo "fcitx-ui-qimpanel isn't compatible with Sogou Pinyin package, so uninstall it."
sudo apt-get remove -y fcitx-ui-qimpanel
sudo apt-get purge -y ibus

if ! dpkg -s "sogoupinyin" &>/dev/null; then
    echo "Install Sogou Pinyin dependencies."
    sudo apt-get install -y \
        libgsettings-qt1 \
        libqt5qml5 \
        libqt5quick5 \
        libqt5quickwidgets5 \
        qml-module-qtquick2

    echo "Install Sogou Pinyin."
    wget -O- https://shurufa.sogou.com/linux | grep -E "https://ime-sec.*?amd64.deb" -o | xargs wget -O /tmp/sogou-pinyin.deb
    sudo gdebi -n /tmp/sogou-pinyin.deb
else
    echo "Sogou Pinyin is installed."
fi

# Free Download Manager
if ! dpkg -s "freedownloadmanager" &>/dev/null; then
    echo "Install Free Download Manager."
    wget -O /tmp/freedownloadmanager.deb https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo gdebi -n /tmp/freedownloadmanager.deb
else
    echo "Free Download Manager is installed."
fi

# Greenfish Icon Editor Pro
if ! dpkg -s "gfie" &>/dev/null; then
    echo "Install Greenfish Icon Editor Pro."
    wget -O gfie.deb http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n gfie.deb
else
    echo "Greenfish Icon Editor Pro is installed."
fi

# Node, npm, nvm
# https://github.com/nvm-sh/nvm
echo "Install nvm."
wget -O- "${GITHUB_PROXY}https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" |
    sed "s@https://raw.githubusercontent.com@${GITHUB_PROXY}https://raw.githubusercontent.com@g" |
    sed "s@https://github.com@${GITHUB_PROXY}https://github.com@g" |
    bash

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

echo "Install latest version LTS nodejs."
nvm install --lts

if [[ -n "${NVM_NODEJS_ORG_MIRROR}" ]]; then
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" "${HOME}/.bashrc"; then
        echo "export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" >>"${HOME}/.bashrc"
        echo "NVM_NODEJS_ORG_MIRROR is set to ${NVM_NODEJS_ORG_MIRROR}"
    fi
fi

touch "${HOME}/.npmrc"
if [[ -n "${NPM_REGISTRY_MIRROR}" ]]; then
    if ! grep -q "registry" "${HOME}/.npmrc"; then
        echo "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
        echo "NPM_REGISTRY_MIRROR is set to ${NPM_REGISTRY_MIRROR}"
    fi
fi

echo "Update npm."
npm update -g

# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if ! dpkg -s "miktex" &>/dev/null; then
    echo "Install MiKTeX."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install -y miktex
else
    echo "MiKTeX is installed."
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
initexmf --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/

echo "Install some extra apps."
sudo apt-get install -y \
    android-sdk-platform-tools \
    audacity \
    bat \
    calibre \
    copyq \
    digikam \
    fd-find \
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
    echo "Install Wine."
    wget -O /tmp/ukylin-wine.deb https://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
    sudo gdebi -n /tmp/ukylin-wine.deb
else
    echo "Wine is installed."
fi

# WeChat
if ! dpkg -s "ukylin-wechat" &>/dev/null; then
    echo "Install WeChat."
    wget -O /tmp/ukylin-wechat.deb https://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
    sudo gdebi -n /tmp/ukylin-wechat.deb
else
    echo "WeChat is installed."
fi

# WeChat Work
if ! dpkg -s "ukylin-wxwork" &>/dev/null; then
    echo "Install WeChat Work."
    wget -O /tmp/ukylin-wxwork.deb https://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
    sudo gdebi -n /tmp/ukylin-wxwork.deb
else
    echo "WeChat Work is installed."
fi

# Tencent Meeting
if ! dpkg -s "ukylin-tencentmeeting" &>/dev/null; then
    echo "Install Tencent Meeting."
    wget -O /tmp/ukylin-tencentmeeting.deb https://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64.deb
    sudo gdebi -n /tmp/ukylin-tencentmeeting.deb
else
    echo "Tencent Meeting is installed."
fi

# Photoshop CS6
if ! dpkg -s "ukylin-ps6" &>/dev/null; then
    echo "Install Photoshop CS6."
    wget -O /tmp/ukylin-ps6.deb https://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
    sudo gdebi -n /tmp/ukylin-ps6.deb
else
    echo "Photoshop CS6 is installed."
fi

# Some Chinese apps.
# Xunlei
if ! dpkg -s "com.xunlei.download" &>/dev/null; then
    echo "Install Xunlei."
    wget -O /tmp/xunlei.deb https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
    sudo gdebi -n /tmp/xunlei.deb
else
    echo "Xunlei is installed."
fi

# WPS
if ! dpkg -s "wps-office" &>/dev/null; then
    echo "Install WPS."
    wget -O /tmp/wps-office.deb https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
    sudo gdebi -n /tmp/wps-office.deb
else
    echo "WPS is installed."
fi

# # Install symbol fonts.
# if [ ! -f "wps_symbol_fonts.zip" ]; then
#   echo "wps_symbol_fonts.zip not exist, exit…"
#   exit 1
# fi

# echo "unzip file wps_symbol_fonts.zip …"
# unzip wps_symbol_fonts.zip -d wps_symbol_fonts
# if [ 0 -ne $? ]; then
#     echo "unzip wps_symbol_fonts.zip failed, exit…"
#     exit 1
# fi

# echo "mv wps_symbol_fonts to /usr/share/fonts/ …"
# sudo mv wps_symbol_fonts /usr/share/fonts/
# if [ 0 -ne $? ]; then
#     echo "mv wps_symbol_fonts to /usr/share/fonts/ failed, exit…"
#     exit 1
# fi

# cd /usr/share/fonts/wps_symbol_fonts/
# if [ 0 -ne $? ]; then
#     echo "cd to /usr/share/fonts/ failed, exit…"
#     exit 1
# fi

# sudo mkfontscale
# if [ 0 -ne $? ]; then
#     echo "sudo mkfontscale failed, exit…"
#     exit 1
# fi

# sudo mkfontdir
# if [ 0 -ne $? ]; then
#     echo "sudo mkfontdir, exit…"
#     exit 1
# fi

# sudo fc-cache
# if [ 0 -ne $? ]; then
#     echo "sudo fc-cache, exit…"
#     exit 1
# fi

# Tor Browser
TOR_BROWSER_LATEST_VERSION=$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" | jq -r ".tag_name" | sed "s/.*-//g")

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

    echo "Install Tor Browser."
    wget -O /tmp/tor-browser.tar.xz "${GITHUB_PROXY}https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${TOR_BROWSER_LATEST_VERSION}/tor-browser-linux64-${TOR_BROWSER_LATEST_VERSION}_ALL.tar.xz"

    [[ -d /tmp/tor-browser-tmp ]] && rm -r /tmp/tor-browser-tmp
    7z x -o/tmp/tor-browser-tmp /tmp/tor-browser.tar.xz
    7z x -o/tmp/tor-browser-tmp /tmp/tor-browser-tmp/*.tar
    cp -r /tmp/tor-browser-tmp/tor-browser "${HOME}/"

    chmod +x "${HOME}/tor-browser/Browser/start-tor-browser"
    "${HOME}/tor-browser/Browser/start-tor-browser" --register-app

    [[ -d "${HOME}/.tor-browser" ]] || mkdir "${HOME}/.tor-browser"
    echo "${TOR_BROWSER_LATEST_VERSION}" >"${HOME}/.tor-browser/VERSION"
else
    echo "Tor Browser is installed."
fi

echo "Uninstall unnecessary apps."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Check installed apps' update
sudo apt-get update -y
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
VTOY_API_URL=https://api.github.com/repos/ventoy/vtoyboot/releases/latest
VTOY_VERSION=$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${VTOY_API_URL}" | jq -r ".tag_name" | tr -d "v")

echo "Download vtoyboot ${VTOY_VERSION}."
wget -O "/tmp/vtoyboot.iso" "${GITHUB_PROXY}$(wget "${HEADERPARAM}" "${HEADERAUTH}" -O- "${VTOY_API_URL}" | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
[[ -d /tmp/vtoyboot-tmp ]] && rm -r /tmp/vtoyboot-tmp
7z x -o/tmp/vtoyboot-tmp /tmp/vtoyboot.iso
7z x -o/tmp/vtoyboot-tmp /tmp/vtoyboot-tmp/*.tar.gz
7z x -o/tmp/vtoyboot-tmp /tmp/vtoyboot-tmp/*.tar

echo "Run vtoyboot."
cd "/tmp/vtoyboot-tmp/vtoyboot-${VTOY_VERSION}" || exit
sudo bash "./vtoyboot.sh"

echo "All done! Run poweroff to shutdown pc, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder."

# TODO freemind, axure,
