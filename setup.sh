#!/usr/bin/env bash

# A simple script to setup up a new Ubuntu (22.04+) or Debian (12+) installation.
# Inspired by https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default.
: "${DEBUG:="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace

### Configurations
: "${APT_MIRROR:="https://mirrors.ustc.edu.cn"}"
: "${CTAN_MIRROR:="https://mirrors.ustc.edu.cn"}"
: "${LOCALE:="zh_CN"}"
: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"
: "${VTOYBOOT:="true"}"

SCRIPT_DIR="$(dirname "$(readlink -f "${0}")")"
mkdir -p "$SCRIPT_DIR/tmp"
TEMP_DIR="$SCRIPT_DIR/tmp"

OS_ID=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)
OS_VERSION_ID=$(awk -F= '$1=="VERSION_ID" { print $2 ;}' /etc/os-release | tr -d '"')
OS_VERSION_CODENAME=$(awk -F= '$1=="VERSION_CODENAME" { print $2 ;}' /etc/os-release)

export DEBIAN_FRONTEND=noninteractive

### Functions
function get_package_version() {
    if dpkg -s "$1" &>/dev/null; then
        dpkg -s "$1" | grep "^Version:" | cut -f2 -d " "
    else
        echo "not_installed"
    fi
}

### APT local mirror
[[ -e /etc/apt/sources.list.backup ]] || sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.backup

[[ "$OS_ID" == "debian" ]] && {
    sudo tee /etc/apt/sources.list <<EOF
# See https://wiki.debian.org/SourcesList for more information.
deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME main non-free-firmware
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME main non-free-firmware

deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-updates main non-free-firmware
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-updates main non-free-firmware

deb http://security.debian.org/debian-security/ $OS_VERSION_CODENAME-security main non-free-firmware
# deb-src http://security.debian.org/debian-security/ $OS_VERSION_CODENAME-security main non-free-firmware

# Backports allow you to install newer versions of software made available for this release
deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-backports main non-free-firmware
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-backports main non-free-firmware
EOF
}

[[ "$OS_ID" == "ubuntu" ]] && {
    sudo tee /etc/apt/sources.list <<EOF
deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME main restricted universe multiverse
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME main restricted universe multiverse

deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-security main restricted universe multiverse
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-security main restricted universe multiverse

deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-updates main restricted universe multiverse
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-updates main restricted universe multiverse

deb $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-backports main restricted universe multiverse
# deb-src $APT_MIRROR/$OS_ID $OS_VERSION_CODENAME-backports main restricted universe multiverse
EOF
}

sudo apt-get update

### Base packages
sudo apt-get install -y apt-transport-https binutils build-essential bzip2 ca-certificates coreutils curl desktop-file-utils file g++ gcc gdebi gpg gzip libfuse2 jq make man-db net-tools ntp p7zip-full patch procps sed software-properties-common tar unzip wget zip

### Drivers
[[ "$OS_ID" == "ubuntu" ]] && sudo apt-get install -y bcmwl-kernel-source nvidia-driver-530

### Fonts
sudo apt-get install -y fonts-droid-fallback fonts-firacode fonts-noto-color-emoji fonts-open-sans fonts-roboto fonts-stix

### Locale
[[ "$LOCALE" == "zh_CN" ]] && sudo apt-get install -y fonts-arphic-ukai fonts-arphic-uming fonts-noto-cjk fonts-noto-cjk-extra

sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"

# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
# cat ~/.config/user-dirs.dirs
mkdir -p "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Music" "$HOME/Pictures" "$HOME/Public" "$HOME/Templates" "$HOME/Videos"
xdg-user-dirs-update --set DESKTOP     "$HOME/Desktop"
xdg-user-dirs-update --set DOCUMENTS   "$HOME/Documents"
xdg-user-dirs-update --set DOWNLOAD    "$HOME/Downloads"
xdg-user-dirs-update --set MUSIC       "$HOME/Music"
xdg-user-dirs-update --set PICTURES    "$HOME/Pictures"
xdg-user-dirs-update --set PUBLICSHARE "$HOME/Public"
xdg-user-dirs-update --set TEMPLATES   "$HOME/Templates"
xdg-user-dirs-update --set VIDEOS      "$HOME/Videos"

### Theme
# Window Manager theme: Materia https://github.com/nana-4/materia-theme
# Icon theme: Papirus https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
sudo apt-get install -y materia-gtk-theme papirus-icon-theme

# For GTK3
command -v gsettings &>/dev/null && {
    gsettings set org.gnome.desktop.interface gtk-theme  "Materia"
    gsettings set org.gnome.desktop.wm.preferences theme "Materia"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus"
}

# For GTK2
command -v xfconf-query &>/dev/null && {
    xfconf-query -c xsettings -p /Net/ThemeName     -s "Materia"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"
    xfconf-query -c xfwm4     -p /general/theme     -s "Materia"

    # Fonts
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Fira Code 10"
    xfconf-query -c xsettings -p /Gtk/FontName          -s "Open Sans 10"
    xfconf-query -c xfwm4     -p /general/title_font    -s "Open Sans 10"
    [[ "$LOCALE" == "zh_CN" ]] && {
        xfconf-query -c xsettings -p /Gtk/FontName       -s "Noto Sans CJK SC 9"
        xfconf-query -c xfwm4     -p /general/title_font -s "Noto Sans CJK SC 9"
    }

}

# Plank
sudo apt-get install -y plank
[[ -e /etc/xdg/autostart/plank.desktop ]] || sudo cp -f /usr/share/applications/plank.desktop /etc/xdg/autostart

### Free Download Manager
function install_fdm() {
    LATEST_VERSION=$(wget -qO- "https://www.freedownloadmanager.org/board/viewtopic.php?f=1&t=17900" | grep -Po "([\d.]+)\s*\[\w+.*?STABLE" | head -n 1 | cut -f1 -d " ")
    CURRENT_VERSION=$(get_package_version freedownloadmanager)

    [[ "${LATEST_VERSION}" == "${CURRENT_VERSION}" ]] || {
        wget -O "$TEMP_DIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
        sudo gdebi -n "$TEMP_DIR/freedownloadmanager.deb"
    }
}
install_fdm

[[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]] && sudo rm /etc/apt/sources.list.d/freedownloadmanager.list

### Google Chrome https://google.cn/chrome
command -v google-chrome-stable &>/dev/null || {
    wget -O "$TEMP_DIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n "$TEMP_DIR/google-chrome.deb"
}

### Greenfish Icon Editor Pro
function install_gfie(){
    LATEST_VESION="$(wget -qO- "http://greenfishsoftware.org/gfie.php#apage" | grep -Po "Latest.+stable.+release\s\([\d.]+\)" | grep -Po "[\d.]+")"
    CURRENT_VERSION=$(get_package_version gfie)

    [[ "$LATEST_VESION" == "$CURRENT_VERSION" ]] || {
        wget -O "$TEMP_DIR/gfie.deb" "http://greenfishsoftware.org/dl/gfie/gfie-$LATEST_VESION.deb"
        sudo gdebi -n "$TEMP_DIR/gfie.deb"
    }
}
install_gfie

### Onedriver: https://github.com/jstaf/onedriver
function install_onedriver(){
    wget -q -O "$TEMP_DIR/onedriver.txt" "https://software.opensuse.org/download.html?project=home%3Ajstaf&package=onedriver"
    DOWNLOAD_URL="$(grep -Pio "https://.+$OS_ID\_\d+.+amd64\.deb" "$TEMP_DIR/onedriver.txt" | sort -r | head -n 1)"

    # Check if have package for current OS version
    grep -Pioq "https://.+$OS_ID\_$OS_VERSION_ID.+amd64\.deb" "$TEMP_DIR/onedriver.txt" && DOWNLOAD_URL="$(grep -Pio "https://.+$OS_ID\_$OS_VERSION_ID.+amd64\.deb" "$TEMP_DIR/onedriver.txt" | sort -r | head -n 1)"

    LATEST_VESION="$(basename "$DOWNLOAD_URL" | cut -f2 -d "_")"
    CURRENT_VERSION=$(get_package_version onedriver)

    [[ "$LATEST_VESION" == "$CURRENT_VERSION" ]] || {
        wget -O "$TEMP_DIR/onedriver.deb" "$DOWNLOAD_URL"
        sudo gdebi -n "$TEMP_DIR/onedriver.deb"
    }
}
install_onedriver

### Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
command -v microsoft-edge-stable &>/dev/null || {
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
}

### Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
command -v code &>/dev/null || {
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
}

### TeX
command -v latex &>/dev/null || {
    wget -P "$TEMP_DIR/" "$CTAN_MIRROR/CTAN/systems/texlive/tlnet/install-tl-unx.tar.gz"
    tar --extract --gz --directory "$TEMP_DIR/install-tl-unx" --file "$TEMP_DIR/install-tl-unx.tar.gz"
    cd "$TEMP_DIR/install-tl-unx" || exit 1
    perl ./install-tl --no-interaction --scheme=basic --no-doc-install --no-src-install --location "$CTAN_MIRROR/CTAN/systems/texlive/tlnet"
    #  PATH=/usr/local/texlive/2023/bin/x86_64-linux:$PATH 
}
# tlmgr option repository "$CTAN_MIRROR/CTAN/systems/texlive/tlnet"
# tlmgr update --self --all
# tlmgr install ctex

### Node
wget -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/https://raw.githubusercontent.com|g" -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | bash

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts

grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc" || echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"

touch "$HOME/.npmrc"
grep -q "registry=" "$HOME/.npmrc" || echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"

# sudo chown -R 1000:1000 "$HOME/.npm"
# command -v nativefier &>/dev/null || npm install -g nativefier

npm upgrade -g

### GitHub Releases DEB apps
# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME="$1"
    PACKAGE_NAME="$2"
    PATTERN="$3"

    wget -q -O "$TEMP_DIR/$PACKAGE_NAME.json" "https://api.github.com/repos/$REPO_NAME/releases/latest"

    VERSION_LATEST="$(jq -r ".tag_name" "$TEMP_DIR/$PACKAGE_NAME.json" | tr -d "v")"
    VERSION_INSTALLED="$(get_package_version "$PACKAGE_NAME")"

    [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]] || {
        jq -r ".assets[].browser_download_url" "$TEMP_DIR/$PACKAGE_NAME.json" | grep -P "${PATTERN}" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/$PACKAGE_NAME.deb"
        sudo gdebi -n "$TEMP_DIR/$PACKAGE_NAME.deb"
    }
}

# install_github_releases_apps vercel/hyper hyper "amd64\.deb"
# install_github_releases_apps Zettlr/Zettlr zettlr "amd64\.deb"
install_github_releases_apps dbeaver/dbeaver          dbeaver-ce       "amd64\.deb"
install_github_releases_apps jgm/pandoc               pandoc           "amd64\.deb"
install_github_releases_apps jgraph/drawio-desktop    draw.io          "amd64.*\.deb"
install_github_releases_apps localsend/localsend      localsend        "x86-64\.deb"
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop "x64\.deb"
install_github_releases_apps peazip/PeaZip            peazip           "GTK2-1_amd64\.deb"
install_github_releases_apps sharkdp/fd               fd-musl          "amd64\.deb"
install_github_releases_apps shiftkey/desktop         github-desktop   "\.deb"

### GitHub Releases AppImage apps
# Joplin
wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | sed -E 's|https://objects\.joplinusercontent\.com/(v\$\{RELEASE_VERSION\}/Joplin-\$\{RELEASE_VERSION\}\.AppImage)\?source=LinuxInstallScript\&type=\$DOWNLOAD_TYPE|https://ghproxy.com/https://github.com/laurent22/joplin/releases/download/\1|g' | bash

### Proxy
# Tor Browser
# It's recommended using Tor Browser to update itself
function install_tor_browser() {
    wget -q -O "$TEMP_DIR/tor-browser.json" "https://api.github.com/repos/TheTorProject/gettorbrowser/releases"
    LATEST_VERSION=$(jq -r '.tag_name' "$TEMP_DIR/tor-browser.json" | grep "linux64-" | head -n 1 | cut -f4 -d "\"" | cut -f2 -d "-")

    [[ -e "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" ]] || {
        grep -Po "https://.+linux64-.+_ALL\.tar\.xz" "$TEMP_DIR/tor-browser.json" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/tor-browser.tar.xz"

        mkdir -p "$HOME/.tor-browser"
        tar --extract --xz --directory "$HOME/.tor-browser" --file "$TEMP_DIR/tor-browser.tar.xz"
        "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --register-app
    }
}
install_tor_browser

mkdir -p "$HOME/.config/autostart"
[[ -e "$HOME/.config/autostart/start-tor-browser.desktop" ]] || cp -f "$HOME/.local/share/applications/start-tor-browser.desktop" "$HOME/.config/autostart"

# Use Tor with proxychains4
sudo apt-get install -y proxychains4
grep -P "^socks5\s*127\.0\.0\.1\s*9150" /etc/proxychains4.conf || sudo sed -i -e "s|^socks.*$|socks5  127.0.0.1 9150|g" /etc/proxychains4.conf

### GVim
sudo apt-get install -y git vim vim-gtk3

mkdir -p "$HOME/.vim/autoload"
[[ -f "$HOME/.vim/autoload/pathogen.vim" ]] || wget -O "$HOME/.vim/autoload/pathogen.vim" https://ghproxy.com/https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim

function install_vim_plugin() {
    local REPO_NAME PLUGIN_NAME
    REPO_NAME="$1"
    PLUGIN_NAME="$(basename "$REPO_NAME")"

    mkdir -p "$HOME/.vim/bundle"
    if [[ -d "$HOME/.vim/bundle/$PLUGIN_NAME" ]]; then
        cd "$HOME/.vim/bundle/$PLUGIN_NAME"
        git pull
    else
        git clone --depth 1 "https://ghproxy.com/https://github.com/$REPO_NAME" "$HOME/.vim/bundle/$PLUGIN_NAME"
    fi
}

install_vim_plugin yianwillis/vimcdoc
install_vim_plugin sheerun/vim-polyglot
install_vim_plugin vim-airline/vim-airline
install_vim_plugin dracula/vim

cd "$SCRIPT_DIR" || exit 1

# vimrc
tee "$HOME/.vimrc" <<"EOF"
execute pathogen#infect()
syntax on
colorscheme dracula
set history=700
filetype plugin on
filetype indent on
set autoread
let mapleader = ","
let g:mapleader = ","
nmap <leader>w :w!<cr>
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
" language messages en_US.UTF-8
" set langmenu=en_US.UTF-8
language messages zh_CN.UTF-8
set langmenu=zh_CN.UTF-8
source $VIMRUNTIME/delmenu.vim
source $VIMRUNTIME/menu.vim
if has("mac") || has("macunix")
  set gfn=Fira\ Code:h9,Source\ Code\ Pro:h9,Menlo:h9
elseif has("win16") || has("win32")
  set gfn=Fira\ Code:h9,Source\ Code\ Pro:h9,Courier\ New:h9
endif
set wildmenu
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
  set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
else
  set wildignore+=.git\*,.hg\*,.svn\*
endif
set ruler
set cmdheight=1
set hid
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
if has('mouse')
  set mouse=a
endif
set ignorecase
set smartcase
set hlsearch
set incsearch 
set lazyredraw 
set magic
set showmatch
set mat=2
set noerrorbells
set novisualbell
set t_vb=
set tm=500
set foldcolumn=1
if has("gui_running")
  set guioptions-=T
  set guioptions-=e
  set guitablabel=%M\ %t
endif
set ffs=unix,dos,mac
set nobackup
set nowb
set noswapfile
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set lbr
set tw=500
set autoindent
set smartindent
set wrap
vnoremap <silent> * :call VisualSelection('f', '')<CR>
vnoremap <silent> # :call VisualSelection('b', '')<CR>
map j gj
map k gk
map <silent> <leader><cr> :noh<cr>
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
map <leader>bd :Bclose<cr>
map <leader>ba :1,1000 bd!<cr>
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove 
map <leader>t<leader> :tabnext 
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
map <leader>cd :cd %:p:h<cr>:pwd<cr>
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry
" https://github.com/vim-airline/vim-airline/issues/1300#issuecomment-255698405
let g:airline#extensions#disable_rtp_load=1
EOF

### Extras
sudo apt-get install -y android-sdk-platform-tools copyq ffmpeg filezilla flameshot ghostscript gimp inkscape libvips-tools mupdf mupdf-tools neofetch network-manager-openvpn-gnome openvpn pdfarranger scribus vlc
# sudo apt-get install -y scrcpy


### Cleaning
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
function install_vtoyboot() {
    wget -q -O "$TEMP_DIR/vtoyboot.json" "https://api.github.com/repos/TheTorProject/gettorbrowser/releases"
    LATEST_VERSION=$(jq -r ".tag_name" "$TEMP_DIR/vtoyboot.json" | tr -d "v")

    INSTALLED_VERSION=not_installed
    find "$HOME/.vtoyboot/" -maxdepth 1 -type d -name "vtoyboot-*" &>/dev/null && INSTALLED_VERSION=$(find "$HOME/.vtoyboot/" -maxdepth 1 -type d -name "vtoyboot-*" | grep -Po "vtoyboot-.*" | cut -f2 -d "-")

    [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]] || {
        # Remove old version.
        [[ -d "$HOME/.vtoyboot" ]] && rm -rf "$HOME/.vtoyboot"

        # Install new version.
        jq -r ".assets[].browser_download_url" "$TEMP_DIR/vtoyboot.json" | grep .iso | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/vtoyboot.iso"

        7z x -o"$TEMP_DIR" "$TEMP_DIR/vtoyboot.iso"
        mkdir -p "$HOME/.vtoyboot"
        tar --extract --gz --directory "$HOME/.vtoyboot" --file "$TEMP_DIR/vtoyboot-$LATEST_VERSION.tar.gz"
    }

    cd "$HOME/.vtoyboot/vtoyboot-$LATEST_VERSION" || exit 1
    sudo bash "./vtoyboot.sh"
    cd "$OLDPWD" || exit 1
    echo "Completed!" && exit 0
}

[[ "$VTOYBOOT" == "true" ]] && install_vtoyboot
