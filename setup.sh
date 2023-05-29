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
: "${VTOYBOOT:="false"}"

[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1

function log() {
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
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
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    log "Removing Free Download Manager mirror list..."
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
else
    log "Free Download Manager mirror list doesn't exist."
fi

# Using APT mirror.
if [[ -f /etc/apt/sources.list ]]; then
    log "APT mirror is set to $APT_MIRROR."
    sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
        -e "s|http:|https:|g" /etc/apt/sources.list
else
    log "There's no sources.list."
fi

log "Updating APT..."
sudo apt-get update -qq

log "Insatlling or updating BCM4360 wifi driver..."
sudo apt-get install -y dkms bcmwl-kernel-source

log "Installing or updating some base packages..."
sudo apt-get install -y apt-transport-https aria2 bat binutils build-essential bzip2 ca-certificates coreutils curl \
    fd-find ffmpeg file gcc g++ gdebi gpg gzip jq libfuse2 lsb-release make man-db net-tools ntp \
    p7zip p7zip-full patch procps proxychains4 ripgrep sed software-properties-common tar unzip wget zip

# Git latest version
if [[ -x "$(command -v git)" ]]; then
    log "Git is installed."
else
    log "Adding Git apt repository..."
    sudo add-apt-repository -y ppa:git-core/ppa
    
    log "Installing Git..."
    sudo apt-get update -qq
    sudo apt-get install -y git
fi

# Google Chrome: https://google.cn/chrome
if [[ -x "$(command -v google-chrome-stable)" ]]; then
    log "Google Chrome is installed."
else
    log "Downloading Google Chrome..."
    wget -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    log "Installing Google Chrome..."
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
fi


# Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if [[ -x "$(command -v microsoft-edge-stable)" ]]; then
    log "Microsoft Edge is installed."
else
    log "Adding Microsoft Edge apt repository..."
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | \
        sudo tee /etc/apt/sources.list.d/microsoft-edge.list

    log "Installing Microsoft Edge..."
    sudo apt-get update -qq
    sudo apt-get install -y microsoft-edge-stable
fi

# Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if [[ -x "$(command -v code)" ]]; then
    log "Visual Studio Code is installed."
else
    log "Adding Visual Studio Code apt repository..."
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list

    log "Installing Visual Studio Code..."
    sudo apt-get update -qq
    sudo apt-get install -y code
fi

# Flatpak: https://flatpak.org/setup/Ubuntu
if [[ -x "$(command -v flatpak)" ]]; then
    log "Flatpak is installed."
else
    log "Installing Flatpak..."
    sudo apt-get install -y flatpak gnome-software-plugin-flatpak

    log "Adding Flatpak remote repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    die "To complete setup, restart your system. run: sudo shutdown -r now" 0
fi

flatpak install --or-update -y flathub com.bitwarden.desktop
flatpak install --or-update -y flathub com.jgraph.drawio.desktop
flatpak install --or-update -y flathub io.dbeaver.DBeaverCommunity
flatpak install --or-update -y flathub io.github.peazip.PeaZip
flatpak install --or-update -y flathub io.github.shiftey.Desktop
flatpak install --or-update -y flathub net.cozic.joplin_desktop
flatpak install --or-update -y flathub net.xmind.XMind
flatpak install --or-update -y flathub org.localsend.localsend_app

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
if [[ $LOCALE == "zh_CN" ]]; then
    log "Installing Chinese language pack..."
    sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans

    log "Installing Chinese fonts..."
    sudo apt-get install -y \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-noto-cjk \
        fonts-noto-cjk-extra
fi

log "Changing locale to $LOCALE..."
sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"


# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
# cat ~/.config/user-dirs.dirs
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
if [[ -n "$(command -v albert)" ]]; then
    log "Albert is installed."
else
    log "Adding Albert apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    wget -qO- "https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null

    log "Installing Albert..."
    sudo apt-get update -qq
    sudo apt-get install -y albert
fi

# Onedriver: https://github.com/jstaf/onedriver
if [[ -n "$(command -v onedriver)" ]]; then
    log "Onedriver is installed."
else
    log "Adding Onedriver apt repository..."
    echo "deb http://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$(lsb_release -rs)/ /" | \
        sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null

    log "Installing Onedriver..."
    sudo apt-get update -qq
    sudo apt-get install -y onedriver
fi

# Greenfish Icon Editor Pro
# TODO update
if [[ -n "$(command -v gfie)" ]]; then
    log "Greenfish Icon Editor Pro is installed."
else
    log "Installing Greenfish Icon Editor Pro..."
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
fi

# Just: https://github.com/casey/just
if [[ -n "$(command -v just)" ]]; then
    log "Just is installed."
else
    log "Adding Just apt repository..."
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | \
        sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | \
        sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list

    log "Installing Just..."
    sudo apt-get update -qq
    sudo apt-get install -y just
fi

# FSearch: https://github.com/cboxdoerfer/fsearch
if [[ -n "$(command -v fsearch)" ]]; then
    log "FSearch is installed."
else
    log "Adding FSearch apt repository..."
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable

    log "Installing FSearch..."
    sudo apt-get update -qq
    sudo apt-get install -y fsearch
fi

# Free Download Manager
log "Downloading Free Download Manager latest version..."
wget -O "$TMPDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb

[[ -d "$TMPDIR/freedownloadmanager" ]] || mkdir -p "$TMPDIR/freedownloadmanager"
ar p "$TMPDIR/freedownloadmanager.deb" control.tar.xz | tar --extract --xz --directory "$TMPDIR/freedownloadmanager"
FDM_LATEST_VERSION="$(cat "$TMPDIR/freedownloadmanager/control" | grep Version: | cut -c 10- -)"
FDM_INSTALLED_VERSION="not_installed"

if dpkg -s freedownloadmanager &>/dev/null; then
    FDM_INSTALLED_VERSION="$(dpkg -s freedownloadmanager | grep Version: | cut -c 10- -)"
    log "Free Download Manager $FDM_INSTALLED_VERSION is installed."
fi

if [[ "$FDM_LATEST_VERSION" == *"$FDM_INSTALLED_VERSION"* || "$FDM_INSTALLED_VERSION" == *"$FDM_LATEST_VERSION"* ]]; then
    log "Free Download Manager $FDM_INSTALLED_VERSION is lastest."
else
    log "Installing Free Download Manager $FDM_LATEST_VERSION..."
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
fi


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

if grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
    log "NVM_NODEJS_ORG_MIRROR is set."
else
    echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
    log "NVM_NODEJS_ORG_MIRROR is set to $NVM_NODEJS_ORG_MIRROR."
fi

touch "$HOME/.npmrc"
if grep -q "registry=" "$HOME/.npmrc"; then
    log "NPM_REGISTRY_MIRROR is set."
else
    echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
    log "NPM_REGISTRY_MIRROR is set to $NPM_REGISTRY_MIRROR."
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
    VERSION_LATEST=$(wget -qO- "$API_URL" | jq -r ".tag_name" | tr -d "v")

    if dpkg -s "$PACKAGE_NAME" &>/dev/null; then
        VERSION_INSTALLED=$(dpkg -s "$PACKAGE_NAME" | grep Version: | cut -c 10- -)
        log "$PACKAGE_NAME $VERSION_INSTALLED is installed."
    else
        VERSION_INSTALLED=not_installed
    fi

    if [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]]; then
            log "$PACKAGE_NAME $VERSION_INSTALLED is lastest."
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
if [[ -n "$(command -v miktex)" ]]; then
    log "MiKTeX is installed."
else
    log "Adding MiKTeX apt repository..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/setup/deb $(lsb_release -cs) universe" | \
        sudo tee /etc/apt/sources.list.d/miktex.list

    log "Installing MiKTeX..."
    sudo apt-get update -qq
    sudo apt-get install -y miktex

    # Finish the setup.
    # Before you can use MiKTeX, you have to finish the setup.
    # You can use MiKTeX Console or, if you prefer the command line, `miktexsetup`.
    # https://docs.miktex.org/manual/miktexsetup.html
    # Finish with a shared (system-wide) TeX installation. Executables like lualatex will be installed in /usr/local/bin.
    sudo miktexsetup --shared=yes finish

    # You also may want to enable automatic package installation:
    sudo initexmf --admin --set-config-value \[MPM\]AutoInstall=1

    # If you don't use mirror, you can comment this.
    sudo initexmf --admin --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/
fi

log "Installing some extra apps..."
sudo apt-get install -y android-sdk-platform-tools audacity calibre digikam filezilla flameshot freecad \
    ghostscript gimp handbrake imagemagick inkscape mupdf mupdf-tools neofetch obs-studio openjdk-16-jdk openshot openvpn \
    pdfarranger plank scrcpy scribus vlc xfce4-appmenu-plugin


# Theme
# WM: Materia: https://github.com/nana-4/materia-theme
# Icons: Papirus: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
if dpkg -s materia-gtk-theme &>/dev/null; then
    log "Materia GTK theme is installed."
else
    log "Installing Materia GTK theme..."
    sudo apt-get install -y materia-gtk-theme
fi

if dpkg -s papirus-icon-theme &>/dev/null; then
    log "Papirus icon theme is installed."
else
    log "Adding Papirus apt repository..."
    sudo add-apt-repository -y ppa:papirus/papirus

    log "Installing Papirus icon theme..."
    sudo apt-get update -qq
    sudo apt-get install -y papirus-icon-theme
fi

log "Setting window manager theme to Materia..."
# For GTK3
gsettings set org.gnome.desktop.interface gtk-theme "Materia"
gsettings set org.gnome.desktop.wm.preferences theme "Materia"
# For GTK2
xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
xfconf-query -c xfwm4 -p /general/theme -s "Materia"

log "Setting icon theme to Papirus..."
gsettings set org.gnome.desktop.interface icon-theme "Papirus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"

log "Setting font family and size..."
xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Noto Sans Mono CJK SC 9"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"

# Hardcode-Tray: https://github.com/bilelmoussaoui/Hardcode-Tray
if dpkg -s hardcode-tray &>/dev/null; then
    log "Hardcode Tray is installed."
else
    log "Adding Hardcode Tray apt repository..."
    sudo add-apt-repository -y ppa:papirus/hardcode-tray

    log "Installing Hardcode Tray..."
    sudo apt-get update -qq
    sudo apt-get install -y hardcode-tray
fi

# Some Windows apps on Ubuntu Kylin
# https://www.ubuntukylin.com/applications
if [[ -f /etc/apt/sources.list.d/ubuntukylin.list ]]; then
    log "Ubuntu Kylin mirror list is added."
else
    log "Adding Ubuntu Kylin apt repository..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56583E647FFA7DE7
    echo "deb http://archive.ubuntukylin.com/ubuntukylin $(lsb_release -cs)-partner main" | sudo tee /etc/apt/sources.list.d/ubuntukylin.list
fi

log "Installing Ubuntu Kylin apps..."
sudo apt-get update -qq
sudo apt-get install -y sogoupinyin ukylin-wine ukylin-wxwork ukylin-ps6 com.xunlei.download wps-office weixin wemeet

# Fix ADM  error when launch PS6
if [[ -f "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" ]]; then
    mv  "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" \
        "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl.backup"
fi

# WPS needs to install symbol fonts.
if dpkg -s wps-fonts &>/dev/null; then
    log "WPS fonts is installed."
else
    log "Adding WPS fonts apt repository..."
    sudo add-apt-repository ppa:atareao/atareao 

    log "Installing WPS symbol fonts..."
    sudo apt-get update -qq
    sudo apt-get install -y wps-fonts
fi

# # Wine: https://wiki.winehq.org/Ubuntu_zhcn
# if [[ -n "$(command -v winetricks)" ]]; then
#     log "Wine is installed."
# else
#     log "Installing Wine..."
#     sudo dpkg --add-architecture i386 
#     sudo mkdir -pm755 /etc/apt/keyrings
#     sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        
#     sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources
#     sudo apt-get update -qq
#     sudo apt install -y --install-recommends winehq-stable
# fi

# # Winetricks: https://github.com/Winetricks/winetricks
# log "Installing or Updating Winetricks..."
# wget -q -O "$TMPDIR/winetricks" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
# chmod +x "$TMPDIR/winetricks"
# sudo cp "$TMPDIR/winetricks" /usr/local/bin

# wget -q -O "$TMPDIR/winetricks.bash-completion" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion
# sudo cp "$TMPDIR/winetricks.bash-completion" /usr/share/bash-completion/completions/winetricks



log "Uninstalling unnecessary apps..."
sudo apt-get clean -y
sudo apt-get autoremove -y

log "Checking installed apps' update..."
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
if [[ "$VTOYBOOT" == "true" ]]; then
    VTOY_LATEST_VERSION=$(wget -qO- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")
    VTOY_INSTALLED_VERSION=not_installed
    [[ -e "$HOME/.vtoyboot_version" ]] && VTOY_INSTALLED_VERSION=$(cat "$HOME/.vtoyboot_version")

    if [[ "$VTOY_INSTALLED_VERSION" != "$VTOY_LATEST_VERSION" ]]; then
        # Remove old version.
        [[ -d "$HOME/.vtoyboot" ]] && rm -r "$HOME/.vtoyboot"

        # Install new version.
        log "Downloading vtoyboot $VTOY_LATEST_VERSION..."
        wget -O "$TMPDIR/vtoyboot.iso" "$(wget -qO- https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1)"
        [[ -d "$TMPDIR/vtoyboot-tmp" ]] && rm -r "$TMPDIR/vtoyboot-tmp"
        7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot.iso"
        7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar.gz"
        7z x -o"$TMPDIR/vtoyboot-tmp" "$TMPDIR/vtoyboot-tmp/*.tar"
        cp -r "$TMPDIR/vtoyboot-tmp/vtoyboot-$VTOY_LATEST_VERSION" "$HOME/.vtoyboot"

        # Record version.
        echo "$VTOY_LATEST_VERSION" >"$HOME/.vtoyboot_version"
    fi

    log "Running vtoyboot..."
    cd "$HOME/.vtoyboot" || die "No vtoyboot folder."
    sudo bash "./vtoyboot.sh"

    die "Completed! You can poweroff vbox, and copy the .vdi file to .vdi.vtoy file, and put it on Ventoy ISO scan folder." 0
else
    die "Completed!" 0
fi