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

# Turn on traces, useful while debugging but commented out by default
set -o xtrace

# Variables
export DEBIAN_FRONTEND=noninteractive

APT_MIRROR=mirrors.ustc.edu.cn/ubuntu
# APT_MIRROR=False

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

if [[ "${APT_MIRROR}" != False ]]; then
  echo "APT mirror is set to ${APT_MIRROR}."

  # https://mirrors.ustc.edu.cn/help/ubuntu.html
  sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
  sudo sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
  sudo sed -i 's/http:/https:/g' /etc/apt/sources.list
  sudo apt-get update
fi


echo "Install some base packages."
sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  build-essential \
  bzip2 \
  ca-certificates \
  coreutils \
  curl \
  ffmpeg \
  file \
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


echo "Install Chinese language pack."
sudo apt-get update
sudo apt-get install -y \
  language-pack-gnome-zh-hans \
  language-pack-gnome-zh-hant \
  language-pack-zh-hans \
  language-pack-zh-hant

echo "Install some fonts."
sudo apt-get update
sudo apt-get install -y \
  fonts-arphic-ukai \
  fonts-arphic-uming \
  fonts-firacode \
  fonts-noto-cjk \
  fonts-noto-cjk-extra

echo "Change locale to zh_CN."
sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN


# Google Chrome
# https://google.cn/chrome
if ! dpkg -s "google-chrome-stable" &> /dev/null; then
  echo "Install Google Chrome."
  wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome.deb
else
  echo "Google Chrome is installed."
fi


# Microsoft Edge
# https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if ! dpkg -s "microsoft-edge-stable" &> /dev/null; then
  echo "Install Microsoft Edge."
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
  sudo apt-get update
  sudo apt-get install -y microsoft-edge-stable
else
  echo "Microsoft Edge is installed."
fi


# Visual Studio Code
# https://code.visualstudio.com/docs/setup/linux
if ! dpkg -s "code" &> /dev/null; then
  echo "Install Visual Studio Code."
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
  sudo apt-get update
  sudo apt-get install -y code
else
  echo "Visual Studio Code is installed."
fi


# Onedriver
# https://github.com/jstaf/onedriver
if ! dpkg -s "onedriver" &> /dev/null; then
  echo "Install Onedriver."
  echo 'deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/home:jstaf.list
  curl -fsSL https://download.opensuse.org/repositories/home:jstaf/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg > /dev/null
  sudo apt-get update
  sudo apt-get install -y onedriver
else
  echo "Onedriver is installed."
fi


# FSearch
# https://github.com/cboxdoerfer/fsearch
if ! dpkg -s "fsearch" &> /dev/null; then
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
  VERSION_LATEST=$(curl "${API_URL}" | jq -r ".tag_name" | tr -d "v")
  
  if dpkg -s "${PACKAGE_NAME}" &> /dev/null; then
    VERSION_INSTALLED=$(dpkg -s "${PACKAGE_NAME}" | grep Version | tr -d "Version: ")
  else
    VERSION_INSTALLED=0
  fi

  if [[ "${VERSION_LATEST}" != "${VERSION_INSTALLED}" ]]; then
    echo "Install ${PACKAGE_NAME} ${VERSION_LATEST}."
    wget -O "/tmp/${PACKAGE_NAME}.deb" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "${API_URL}" | jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1)"
    sudo dpkg -i "/tmp/${PACKAGE_NAME}.deb"
  else
    echo "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
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
  VERSION_LATEST=$(curl "${API_URL}" | jq -r ".tag_name" | tr -d "v")

  if [[ -e "${HOME}/.${PACKAGE_NAME}/VERSION" ]]; then
    VERSION_INSTALLED=$(cat "${HOME}/.${PACKAGE_NAME}/VERSION")
  else
    VERSION_INSTALLED=0
  fi

  if [[ "${VERSION_INSTALLED}" != "${VERSION_LATEST}" ]]; then
    # Remove old version
    [[ -e "${HOME}/Desktop/${PACKAGE_NAME}.AppImage" ]] && rm -f "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"
    
    echo "Install ${PACKAGE_NAME} ${VERSION_LATEST}."
    wget -O "/tmp/${PACKAGE_NAME}.AppImage" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "${API_URL}" | jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1)"
    cp "/tmp/${PACKAGE_NAME}.AppImage" "${HOME}/Desktop"
    chmod +x "${HOME}/Desktop/${PACKAGE_NAME}.AppImage"

    # Record version
    echo "${VERSION_LATEST}" > "${HOME}/.${PACKAGE_NAME}/VERSION"
  else
    echo "${PACKAGE_NAME} ${VERSION_LATEST} is lastest."
  fi
}

install_appimage_apps laurent22/joplin
install_appimage_apps localsend/localsend


# Sogou pinyin
# https://shurufa.sogou.com/linux/guide
# should uninstall fcitx-ui-qimpanel first.
echo "Install fcitx config GUI."
sudo apt-get install -y fcitx fcitx-config-gtk

echo "fcitx-ui-qimpanel isn't compatible with Sogou Pinyin package, so uninstall it."
sudo apt-get remove -y fcitx-ui-qimpanel

if ! dpkg -s "sogoupinyin" &> /dev/null; then
  echo "Install Sogou Pinyin dependencies."
  sudo apt-get install -y libgsettings-qt1 libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2

  # Another URL: https://archive.ubuntukylin.com/software/pool/partner/sogoupinyin_2.4.0.3469_amd64.deb
  echo "Install Sogou Pinyin."
  wget -O /tmp/sogou-pinyin.deb https://ime-sec.gtimg.com/202305181446/a3a810d5bc1e188c23d3601fa8a71b0b/pc/dl/gzindex/1680521603/sogoupinyin_4.2.1.145_amd64.deb
  sudo dpkg -i /tmp/sogou-pinyin.deb
else
  echo "Sogou Pinyin is installed."
fi


# Free Download Manager
if ! dpkg -s "freedownloadmanager" &> /dev/null; then
  echo "Install Free Download Manager."
  wget -O /tmp/freedownloadmanager.deb https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb
  sudo dpkg -i /tmp/freedownloadmanager.deb
else
  echo "Free Download Manager is installed."
fi


# Greenfish Icon Editor Pro
if ! dpkg -s "gfie" &> /dev/null; then
  echo "Install Greenfish Icon Editor Pro."
  wget -O gfie.deb http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
  sudo dpkg -i gfie.deb
else
  echo "Greenfish Icon Editor Pro is installed."
fi


# Node, npm, nvm
NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
NPM_REGISTRY_MIRROR=https://registry.npmmirror.com

# https://github.com/nvm-sh/nvm
echo "Install nvm."
curl "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | bash

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

echo "Install latest version LTS nodejs."
nvm install --lts

if [[ ${NVM_NODEJS_ORG_MIRROR} != False ]]; then
  if grep -q "NVM_NODEJS_ORG_MIRROR" "${HOME}/.bashrc"; then
    echo "export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" >>"${HOME}/.bashrc"
    echo "NVM_NODEJS_ORG_MIRROR is set to ${NVM_NODEJS_ORG_MIRROR}"
  fi
fi

touch "${HOME}/.npmrc"
if [[ ${NPM_REGISTRY_MIRROR} ]]; then
  if grep -q "registry" "${HOME}/.npmrc"; then
    echo "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
    echo "NPM_REGISTRY_MIRROR is set to ${NPM_REGISTRY_MIRROR}"
  fi
fi

echo "Update npm."
npm update -g


# MiKTeX
# https://miktex.org/download#ubuntu and 
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if ! dpkg -s "miktex" &> /dev/null; then
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
  aria2 \
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
if ! dpkg -s "ukylin-wine" &> /dev/null; then
  echo "Install Wine."
  wget -O ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
  sudo dpkg -i ukylin-wine.deb
else
  echo "Wine is installed."
fi

# WeChat
if ! dpkg -s "ukylin-wechat" &> /dev/null; then
  echo "Install WeChat."
  wget -O ukylin-wechat.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
  sudo dpkg -i ukylin-wechat.deb
else
  echo "WeChat is installed."
fi

# WeChat Work
if ! dpkg -s "ukylin-wxwork" &> /dev/null; then
  echo "Install WeChat Work."
  wget -O ukylin-wxwork.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
  sudo dpkg -i ukylin-wxwork.deb
else
  echo "WeChat Work is installed."
fi

# Tencent Meeting
if ! dpkg -s "ukylin-tencentmeeting" &> /dev/null; then
  echo "Install Tencent Meeting."
  wget -O ukylin-tencentmeeting.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64.deb
  sudo dpkg -i ukylin-tencentmeeting.deb
else
  echo "Tencent Meeting is installed."
fi

# Photoshop CS6
if ! dpkg -s "ukylin-ps6" &> /dev/null; then
  echo "Install Photoshop CS6."
  wget -O ukylin-ps6.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
  sudo dpkg -i ukylin-ps6.deb
else
  echo "Photoshop CS6 is installed."
fi

# Xunlei
if ! dpkg -s "xunlei" &> /dev/null; then
  echo "Install Xunlei."
  wget -O xunlei.deb https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
  sudo dpkg -i xunlei.deb
else
  echo "Xunlei is installed."
fi

# WPS
if dpkg -s "wps-office" &> /dev/null; then
  echo "Install WPS."
  wget -O wps-office.deb https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
  sudo dpkg -i wps-office.deb
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
TOR_BROWSER_LATEST_VERSION=$(curl "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" | jq -r ".tag_name" | sed "s/.*-//g")

if [[ -e "${HOME}/.tor-browser/VERSION" ]]; then
  TOR_BROWSER_INSTALLED_VERSION=$(cat "${HOME}/.tor-browser/VERSION")
else
  TOR_BROWSER_INSTALLED_VERSION=0
fi

if [[ "${TOR_BROWSER_INSTALLED_VERSION}" != "${TOR_BROWSER_LATEST_VERSION}" ]]; then
  [[ -d "${HOME}/tor-browser" ]] && rm -rf "${HOME}/tor-browser"

  echo "Install Tor Browser."
  wget -O tor-browser.tar.xz "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${TOR_BROWSER_LATEST_VERSION}/tor-browser-linux64-${TOR_BROWSER_LATEST_VERSION}_ALL.tar.xz"

  # 7z x -otor-browser tor-browser.tar.xz
  # 7z x -otor-browser tor-browser/tor-browser.tar
  # cp -r tor-browser/tor-browser "${HOME}/"
  # TODO REMOVE THIS
  tar -xf tor-browser.tar.xz
  cp -r tor-browser "${HOME}/"
  chmod +x "${HOME}/tor-browser/start-tor-browser.desktop"
  "${HOME}/tor-browser/start-tor-browser.desktop" --register-app

  echo "${TOR_BROWSER_LATEST_VERSION}" > "${HOME}/.tor-browser/VERSION"
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
VTOY_VERSION=$(curl "${VTOY_API_URL}" | jq -r ".tag_name" | tr -d "v")

echo "Download vtoyboot ${VTOY_VERSION}."
wget -O "vtoyboot.iso" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "${VTOY_API_URL}" | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
echo "Run vtoyboot"
7z x -ovtoyboot vtoyboot.iso
7z x -ovtoyboot vtoyboot/*.tar.gz
7z x -ovtoyboot vtoyboot/*.tar
sudo bash "vtoyboot/vtoyboot-${VTOY_VERSION}/vtoyboot.sh"


# TODO freemind, axure, 
