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
# Turn on traces, useful while debugging but commented out by default.
: "${DEBUG:="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace

###  Configurations
: "${APT_MIRROR:="https://mirrors.ustc.edu.cn"}"
: "${LOCALE:="zh_CN"}"
: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"
: "${VTOYBOOT:="true"}"

TEMP_DIR="$(mktemp -d)"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)

export DEBIAN_FRONTEND=noninteractive

### Functions
function get_package_version() {
    if dpkg -s "$1" >/dev/null; then
        dpkg -s "$1" | grep "^Version:" | cut -f2 -d " "
    else
        echo "not_installed"
    fi
}

# Installing 3rd party .deb apps from GitHub Releases
install_github_releases_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED API_URL
    REPO_NAME="$1"
    PACKAGE_NAME="$2"
    PATTERN="$3"
    API_URL="https://api.github.com/repos/$REPO_NAME/releases/latest"
    VERSION_LATEST="$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | jq -r ".tag_name" | tr -d "v")"
    VERSION_INSTALLED="$(get_package_version "$PACKAGE_NAME")"

    [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]] || {
        wget -O- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/$PACKAGE_NAME.deb"
        sudo gdebi -n "$TEMP_DIR/$PACKAGE_NAME.deb"
    }
}


# Install vim plugin
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

### APT local mirror
[[ -e /etc/apt/sources.list.backup ]] || sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.backup
sudo tee /etc/apt/sources.list <<EOF
deb $APT_MIRROR/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
# deb-src $APT_MIRROR/ubuntu/ $(lsb_release -cs) main restricted universe multiverse

deb $APT_MIRROR/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
# deb-src $APT_MIRROR/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse

deb $APT_MIRROR/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
# deb-src $APT_MIRROR/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse

deb $APT_MIRROR/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
# deb-src $APT_MIRROR/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
EOF

sudo apt-get update

### Base packages
sudo apt-get install -y apt-transport-https binutils build-essential bzip2 ca-certificates coreutils curl desktop-file-utils file g++ gcc gdebi gpg gzip libfuse2 lsb-release make man-db net-tools ntp p7zip-full patch procps sed software-properties-common tar unzip wget zip

### Drivers
sudo apt-get install -y bcmwl-kernel-source nvidia-driver-530

### Fonts
sudo apt-get install -y fonts-cascadia-code fonts-emojione fonts-droid-fallback fonts-firacode fonts-noto-color-emoji fonts-open-sans fonts-roboto fonts-stix fonts-ubuntu

### Locale
[[ "$LOCALE" == "zh_CN" ]] && sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans fonts-arphic-ukai fonts-arphic-uming fonts-noto-cjk fonts-noto-cjk-extra

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
# Window Manager: Materia: https://github.com/nana-4/materia-theme
# Icons: Papirus: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
dpkg -s materia-gtk-theme >/dev/null || sudo apt-get install -y materia-gtk-theme

dpkg -s papirus-icon-theme >/dev/null || {
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt-get update
    sudo apt-get install -y papirus-icon-theme
}

# For GTK3
command -v gsettings >/dev/null && {
    gsettings set org.gnome.desktop.interface gtk-theme "Materia"
    gsettings set org.gnome.desktop.wm.preferences theme "Materia"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus"
}

# For GTK2
command -v xfconf-query >/dev/null && {
    xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"
    xfconf-query -c xfwm4 -p /general/theme -s "Materia"
    xfconf-query -c xfce4-notifyd -p /theme -s "Default"

    # Fonts
    sudo apt-get install -y fonts-firacode fonts-open-sans
    xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Fira Code 10"
    if [[ "$LOCALE" == "zh_CN" ]]; then
        sudo apt-get install -y fonts-noto-cjk fonts-noto-cjk-extra
        xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
        xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"
    else
        xfconf-query -c xsettings -p /Gtk/FontName -s "Open Sans 10"
        xfconf-query -c xfwm4 -p /general/title_font -s "Open Sans 10"
    fi

    # Plank
    sudo apt-get install -y plank xfce4-appmenu-plugin
    [[ -e /etc/xdg/autostart/plank.desktop ]] || sudo cp -f /usr/share/applications/plank.desktop /etc/xdg/autostart
}


### Ulauncher
command -v ulauncher >/dev/null || {
    sudo add-apt-repository -y ppa:agornostal/ulauncher
    sudo apt update
    sudo apt install -y ulauncher
}

### CopyQ
command -v copyq >/dev/null || {
    sudo add-apt-repository -y ppa:hluk/copyq
    sudo apt-get update
    sudo apt-get install -y copyq
}

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

# repo 在国内连不上，所以直接删掉。通过上述方法从官网安装更新
[[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]] && sudo rm /etc/apt/sources.list.d/freedownloadmanager.list

### FSearch
# https://github.com/cboxdoerfer/fsearch
command -v fsearch >/dev/null || {
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
}

# Git latest version
command -v git >/dev/null || {
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get install -y git
}

### Google Chrome
# https://google.cn/chrome
command -v google-chrome-stable >/dev/null || {
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

### Inkscape
# https://launchpad.net/~inkscape.dev/+archive/ubuntu/stable
command -v inkscape >/dev/null || {
    sudo add-apt-repository -y ppa:inkscape.dev/stable
    sudo apt-get update
    sudo apt-get install -y inkscape
}


### Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
command -v microsoft-edge-stable >/dev/null || {
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
}

### Onedriver: https://github.com/jstaf/onedriver
command -v onedriver >/dev/null || {
    echo "deb https://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$(lsb_release -rs)/ /" | sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
    sudo apt-get install -y onedriver
}

### Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
command -v code >/dev/null || {
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TEMP_DIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TEMP_DIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
}


# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
command -v miktex >/dev/null || {
    wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD6BC243565B2087BC3F897C9277A7293F59E4889" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/miktex.gpg >/dev/null

    echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/setup/deb $(lsb_release -cs) universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install -y miktex

    # https://docs.miktex.org/manual/miktexsetup.html
    # Finish with a shared (system-wide) TeX installation. Executables like lualatex will be installed in /usr/local/bin.
    sudo miktexsetup --shared=yes finish

    # You also may want to enable automatic package installation:
    sudo initexmf --admin --set-config-value \[MPM\]AutoInstall=1

    # If you don't use mirror, you can comment this.
    sudo initexmf --admin --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/
}

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
# command -v nativefier >/dev/null || npm install -g nativefier

npm upgrade -g


### GitHub Releases DEB apps
# install_github_releases_apps Figma-Linux/figma-linux figma-linux .amd64.deb
# install_github_releases_apps OpenBoard-org/OpenBoard openboard "$(lsb_release -rs)_*_amd64.deb"
# install_github_releases_apps vercel/hyper hyper amd64.deb
# install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
install_github_releases_apps flameshot-org/flameshot flameshot "ubuntu-$(lsb_release -rs).amd64.deb"
install_github_releases_apps jgm/pandoc pandoc amd64.deb
# install_github_releases_apps bitwarden/clients bitwarden amd64.deb
# install_github_releases_apps sharkdp/bat bat "bat_*amd64.deb"
install_github_releases_apps jgraph/drawio-desktop draw.io "amd64*.deb"
install_github_releases_apps localsend/localsend localsend x86-64.deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb
install_github_releases_apps peazip/PeaZip peazip .GTK2-1_amd64.deb
install_github_releases_apps sharkdp/fd fd amd64.deb
install_github_releases_apps shiftkey/desktop github-desktop .deb

### GitHub Releases AppImage apps
# Joplin
# 使用 Joplin 官方提供的安装、升级脚本，但是改良两点：
# 1. 使用 GitHub Token 来访问 api 地址，降低访问失败的风险
# 2. 将下载链接替换为代理地址，使得在中国可以访问

wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | sed -E -e 's|https://objects\.joplinusercontent\.com/(v\$\{RELEASE_VERSION\}/Joplin-\$\{RELEASE_VERSION\}\.AppImage)\?source=LinuxInstallScript\&type=\$DOWNLOAD_TYPE|https://ghproxy.com/https://github.com/laurent22/joplin/releases/download/\1|g' -e "s|(\"?https://api\.github\.com)|--header=\"Authorization: Bearer $GITHUB_TOKEN\" \1|g" | bash


### Tor Browser
# It's recommended using Tor Browser to update itself
function install_tor_browser() {
    LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/TheTorProject/gettorbrowser/releases" | grep tag_name | grep "linux64-" | head -n 1 | cut -f4 -d "\"" | cut -f2 -d "-")

    [[ -e "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" ]] || {
        wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | grep -Po "https://.+linux64-.+_ALL\.tar\.xz" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/tor-browser.tar.xz"

        mkdir -p "$HOME/.tor-browser"
        tar --extract --xz --directory "$HOME/.tor-browser" --file "$TEMP_DIR/tor-browser.tar.xz"
        "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --register-app
    }
}
install_tor_browser

mkdir -p "$HOME/.config/autostart"
[[ -e "$HOME/.config/autostart/start-tor-browser.desktop" ]] || cp -f "$HOME/.local/share/applications/start-tor-browser.desktop" "$HOME/.config/autostart"

command -v proxychains4 >/dev/null || sudo apt-get install -y proxychains4

# Use Tor with proxychains4
grep -P "^socks5\s*127\.0\.0\.1\s*9150" /etc/proxychains4.conf && sudo sed -i -e "s|^socks5.*$|socks5  127.0.0.1 9150|g" /etc/proxychains4.conf

### GVim
sudo apt-get install -y vim vim-gtk

mkdir -p "$HOME/.vim/autoload"
[[ -f "$HOME/.vim/autoload/pathogen.vim" ]] || wget -O "$HOME/.vim/autoload/pathogen.vim" https://ghproxy.com/https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim

install_vim_plugin yianwillis/vimcdoc
install_vim_plugin sheerun/vim-polyglot
install_vim_plugin vim-airline/vim-airline
install_vim_plugin dracula/vim

cd "$SCRIPT_DIR" || exit 1

# vimrc
cat >"$HOME/.vimrc" <<"EOF"
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
sudo apt-get install -y android-sdk-platform-tools ffmpeg filezilla ghostscript gimp libvips-tools mupdf mupdf-tools neofetch network-manager-openvpn-gnome openvpn pdfarranger scrcpy scribus vlc


### Cleaning
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
function install_vtoyboot() {
    LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")

    INSTALLED_VERSION=not_installed
    find "$HOME/.vtoyboot/" -maxdepth 1 -type d -name "vtoyboot-*" >/dev/null && INSTALLED_VERSION=$(find "$HOME/.vtoyboot/" -maxdepth 1 -type d -name "vtoyboot-*" | grep -Po "vtoyboot-.*" | cut -f2 -d "-")

    [[ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]] || {
        # Remove old version.
        [[ -d "$HOME/.vtoyboot" ]] && rm -rf "$HOME/.vtoyboot"

        # Install new version.
        wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TEMP_DIR/vtoyboot.iso"

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
