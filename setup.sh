#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Author: David Peng
# Date: 2023-01-13

# Inspired by https://github.com/halvards/vagrant-xfce4-ubuntu 
# https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail

export DEBUG=False
if [[ ${DEBUG} != False ]]; then
  # Turn on traces, useful while debugging but commented out by default
  set -o xtrace
fi

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
  local msg=$1
  local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
  log "$msg"
  exit "$code"
}

# Variables
export DEBIAN_FRONTEND=noninteractive

APT_MIRROR=mirrors.ustc.edu.cn/ubuntu
# APT_MIRROR=False

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

if [[ "${APT_MIRROR}" != False ]]; then
  echo "Using APT proxy: ${APT_MIRROR}."

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

sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN


# Use deb-get to install 3rd party apps.
# https://github.com/wimpysworld/deb-get
echo "Install deb-get."
if [[ ${GITHUB_PROXY} != False ]]; then
  curl -sL "${GITHUB_PROXY}https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get" | \
    sed -i "s#(https://raw\.githubusercontent\.com)#${GITHUB_PROXY}$1#g" | \
    sudo -E bash -s install deb-get
else
  curl -sL "https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get" | \
    sudo -E bash -s install deb-get
fi
deb-get update
deb-get install \
  bat \
  code \
  copyq \
  dbeaver-ce \
  deb-get \
  draw.io \
  fd \
  flameshot \
  fsearch \
  github-desktop \
  google-chrome-stable \
  hyper \
  microsoft-edge-stable \
  motrix \
  obs-studio \
  onedriver \
  pandoc \
  peazip \
  texworks \
  yq \
  zettlr
deb-get upgrade

# Use zap to install AppImage
# https://github.com/srevinsaju/zap
echo "Install zap"
curl "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://raw.githubusercontent.com/srevinsaju/zap/main/install.sh" | bash -s
zap install joplin
zap install --github --from localsend/localsend
zap install --github --from lyswhut/lx-music-desktop
zap upgrade

# Install Sogou pinyin, should uninstall fcitx-ui-qimpanel first.
echo "Install fcitx config GUI."
sudo apt-get install -y fcitx fcitx-config-gtk

echo "fcitx-ui-qimpanel isn't compatible with Sogou Pinyin package, so uninstall it too."
sudo apt-get remove -y fcitx-ui-qimpanel

if ! dpkg -s "sogoupinyin" &> /dev/null; then
  echo "Install Sogou Pinyin dependencies."
  sudo apt-get install -y \
    libgsettings-qt1 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5quickwidgets5 \
    qml-module-qtquick2

  # Another URL: https://archive.ubuntukylin.com/software/pool/partner/sogoupinyin_2.4.0.3469_amd64.deb
  echo "Install Sogou Pinyin."
  wget -O sogou-pinyin.deb https://ime-sec.gtimg.com/202305181446/a3a810d5bc1e188c23d3601fa8a71b0b/pc/dl/gzindex/1680521603/sogoupinyin_4.2.1.145_amd64.deb
  sudo dpkg -i sogou-pinyin.deb
fi


if ! dpkg -s "freedownloadmanager" &> /dev/null; then
  log "Install Free Download Manager."
  wget -O freedownloadmanager.deb https://dn3.freedownloadmanager.org/6/latest/freedownloadmanager.deb
  sudo dpkg -i freedownloadmanager.deb
fi

if ! dpkg -s "gfie" &> /dev/null; then
  log "Install Greenfish Icon Editor Pro."
  wget -O gfie.deb http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
  sudo dpkg -i gfie.deb
fi

NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
NPM_REGISTRY_MIRROR=https://registry.npmmirror.com

# https://github.com/nvm-sh/nvm
log "Install nvm."
curl "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | bash

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

log "Install latest version LTS nodejs."
nvm install --lts

if [[ ${NVM_NODEJS_ORG_MIRROR} != False ]]; then
  if grep -q "NVM_NODEJS_ORG_MIRROR" "${HOME}/.bashrc"; then
    log "Using NVM_NODEJS_ORG_MIRROR: ${NVM_NODEJS_ORG_MIRROR}"
    echo "export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" >>"${HOME}/.bashrc"
  fi
fi

touch "${HOME}/.npmrc"
if [[ ${NPM_REGISTRY_MIRROR} ]]; then
  if grep -q "registry" "${HOME}/.npmrc"; then
    log "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
    log "Using NPM_REGISTRY_MIRROR: ${NPM_REGISTRY_MIRROR}"
  fi
fi

log "Update npm."
npm update -g


# https://miktex.org/download#ubuntu and 
# https://mirrors.bfsu.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if ! dpkg -s "miktex" &> /dev/null; then
  log "Install MiKTeX."
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
  echo "deb http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
  sudo apt-get update
  sudo apt-get install -y miktex
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

log "Install some extra apps."
sudo apt-get install -y \
  android-sdk-platform-tools \
  aria2 \
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
# https://www.ubuntukylin.com/applications/119-cn.html
if ! dpkg -s "ukylin-wine" &> /dev/null; then
  log "Install Wine."
  wget -O ukylin-wine.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wine_70.6.3.25_amd64.deb
  sudo dpkg -i ukylin-wine.deb
fi

if ! dpkg -s "ukylin-wechat" &> /dev/null; then
  log "Install WeChat."
  wget -O ukylin-wechat.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wechat_3.0.0_amd64.deb
  sudo dpkg -i ukylin-wechat.deb
fi

# https://www.ubuntukylin.com/applications/108-cn.html
if ! dpkg -s "ukylin-wxwork" &> /dev/null; then
  log "Install WeChat Work."
  wget -O ukylin-wxwork.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-wxwork_1.0_amd64.deb
  sudo dpkg -i ukylin-wxwork.deb
fi

# https://www.ubuntukylin.com/applications/119-cn.html
if ! dpkg -s "ukylin-tencentmeeting" &> /dev/null; then
  log "Install Tencent Meeting."
  wget -O ukylin-tencentmeeting.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-tencentmeeting_1.0_amd64.deb
  sudo dpkg -i ukylin-tencentmeeting.deb
fi

# https://www.ubuntukylin.com/applications/119-cn.html
if ! dpkg -s "ukylin-ps6" &> /dev/null; then
  log "Install Photoshop."
  wget -O ukylin-ps6.deb http://archive.ubuntukylin.com/software/pool/partner/ukylin-ps6_1.0_amd64.deb
  sudo dpkg -i ukylin-ps6.deb
fi

# https://www.ubuntukylin.com/applications/119-cn.html
if ! dpkg -s "xunlei" &> /dev/null; then
  log "Install Xunlei."
  wget -O xunlei.deb https://archive.ubuntukylin.com/software/pool/partner/com.xunlei.download_1.0.0.1_amd64.deb
  sudo dpkg -i xunlei.deb
fi

if dpkg -s "wps-office" &> /dev/null; then
  log "Install WPS."
  wget -O wps-office.deb https://archive.ubuntukylin.com/software/pool/partner/wps-office_11.1.0.11698_amd64.deb
  sudo dpkg -i wps-office.deb

  # # Install symbol fonts.
  # if [ ! -f "wps_symbol_fonts.zip" ]; then
  #   log "wps_symbol_fonts.zip not exist, exit…"
  #   exit 1
  # fi

  # log "unzip file wps_symbol_fonts.zip …"
  # unzip wps_symbol_fonts.zip -d wps_symbol_fonts
  # if [ 0 -ne $? ]; then
  #     log "unzip wps_symbol_fonts.zip failed, exit…"
  #     exit 1
  # fi

  # log "mv wps_symbol_fonts to /usr/share/fonts/ …"
  # sudo mv wps_symbol_fonts /usr/share/fonts/
  # if [ 0 -ne $? ]; then
  #     log "mv wps_symbol_fonts to /usr/share/fonts/ failed, exit…"
  #     exit 1
  # fi

  # cd /usr/share/fonts/wps_symbol_fonts/
  # if [ 0 -ne $? ]; then
  #     log "cd to /usr/share/fonts/ failed, exit…"
  #     exit 1
  # fi

  # sudo mkfontscale
  # if [ 0 -ne $? ]; then
  #     log "sudo mkfontscale failed, exit…"
  #     exit 1
  # fi

  # sudo mkfontdir
  # if [ 0 -ne $? ]; then
  #     log "sudo mkfontdir, exit…"
  #     exit 1
  # fi

  # sudo fc-cache
  # if [ 0 -ne $? ]; then
  #     log "sudo fc-cache, exit…"
  #     exit 1
  # fi

fi

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
  log "Downloaded Tor Browser."

  # 7z x -otor-browser tor-browser.tar.xz
  # 7z x -otor-browser tor-browser/tor-browser.tar
  # cp -r tor-browser/tor-browser "${HOME}/"
  # TODO REMOVE THIS
  tar -xf tor-browser.tar.xz
  cp -r tor-browser "${HOME}/"
  chmod +x "${HOME}/tor-browser/start-tor-browser.desktop"
  "${HOME}/tor-browser/start-tor-browser.desktop" --register-app

  echo "${TOR_BROWSER_LATEST_VERSION}" > "${HOME}/.tor-browser/VERSION"
fi

log "Uninstall unnecessary apps."
sudo apt-get clean -y
sudo apt-get autoremove -y


VTOY_API=https://api.github.com/repos/ventoy/vtoyboot/releases/latest
VTOY_VERSION=$(curl "${VTOY_API}" | jq -r ".tag_name" | tr -d "v")
log "Download vtoyboot ${VTOY_VERSION}."
wget -O "vtoyboot.iso" "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")$(curl "${VTOY_API}" | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
log "Run vtoyboot"
7z x -ovtoyboot vtoyboot.iso
7z x -ovtoyboot vtoyboot/*.tar.gz
7z x -ovtoyboot vtoyboot/*.tar
sudo bash "vtoyboot/vtoyboot-${VTOY_VERSION}/vtoyboot.sh"


# TODO freemind, axure, 
