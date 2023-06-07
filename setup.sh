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

###  Configurations
: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"
: "${LOCALE:="zh_CN"}"
: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"
: "${VTOYBOOT:="false"}"

TMPDIR="$(mktemp -d)"
export DEBIAN_FRONTEND=noninteractive

### Functions
function get_package_version() {
    if dpkg -s "$1" &>/dev/null; then
        dpkg -s "$1" | grep Version: | cut -f2 -d " "
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

    if ! [[ "$VERSION_LATEST" == *"$VERSION_INSTALLED"* || "$VERSION_INSTALLED" == *"$VERSION_LATEST"* ]]; then
        wget -O- --header="Authorization: Bearer $GITHUB_TOKEN" "$API_URL" | jq -r ".assets[].browser_download_url" | grep "${PATTERN}" | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TMPDIR/$PACKAGE_NAME.deb"
        sudo gdebi -n "$TMPDIR/$PACKAGE_NAME.deb"
    fi
}

# Installing 3rd party .AppImage apps from GitHub Releases
install_appimage_apps() {
    local REPO_NAME PACKAGE_NAME VERSION_LATEST VERSION_INSTALLED
    REPO_NAME="$1"
    PACKAGE_NAME="$2"
    VERSION_LATEST="$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO_NAME/releases/latest" | jq -r ".tag_name" | tr -d "v")"

    if [[ -e "$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION" ]]; then
        VERSION_INSTALLED=$(cat "$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION")
    else
        VERSION_INSTALLED="not_installed"
    fi

    if ! [[ "$VERSION_INSTALLED" == *"$VERSION_LATEST"* || "$VERSION_LATEST" == *"$VERSION_INSTALLED"* ]]; then
        # Remove old version
        [[ -e "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage" ]] && rm -f "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage"

        wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO_NAME/releases/latest" | jq -r ".assets[].browser_download_url" | grep .AppImage | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TMPDIR/$PACKAGE_NAME.AppImage"

        # Install new version
        mkdir -p "$HOME/.AppImageApplications"
        cp "$TMPDIR/$PACKAGE_NAME.AppImage" "$HOME/.AppImageApplications"
        chmod +x "$HOME/.AppImageApplications/$PACKAGE_NAME.AppImage"

        # Record version
        echo "$VERSION_LATEST" >"$HOME/.AppImageApplications/$PACKAGE_NAME.VERSION"
    fi
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

### APT source list
sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" -e "s|http:|https:|g" /etc/apt/sources.list
sudo apt-get update

### Base packages
sudo apt-get install -y apt-transport-https binutils build-essential bzip2 ca-certificates coreutils curl desktop-file-utils file g++ gcc gdebi git gpg gzip jq libfuse2 lsb-release make man-db net-tools ntp p7zip-full patch procps sed software-properties-common tar unzip wget zip

### Drivers
sudo apt-get install -y dkms bcmwl-kernel-source nvidia-driver-530

### Fonts
sudo apt-get install -y fonts-cascadia-code fonts-emojione fonts-droid-fallback fonts-firacode fonts-noto-color-emoji fonts-open-sans fonts-roboto fonts-stix fonts-ubuntu

# Locale
if [[ "$LOCALE" == "zh_CN" ]]; then
    sudo apt-get install -y language-pack-gnome-zh-hans language-pack-zh-hans fonts-arphic-ukai fonts-arphic-uming fonts-noto-cjk fonts-noto-cjk-extra
fi

sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"

# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
# cat ~/.config/user-dirs.dirs
mkdir -p "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Music" "$HOME/Pictures" "$HOME/Public" "$HOME/Templates" "$HOME/Videos"
xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
xdg-user-dirs-update --set DOWNLOAD "$HOME/Downloads"
xdg-user-dirs-update --set MUSIC "$HOME/Music"
xdg-user-dirs-update --set PICTURES "$HOME/Pictures"
xdg-user-dirs-update --set PUBLICSHARE "$HOME/Public"
xdg-user-dirs-update --set TEMPLATES "$HOME/Templates"
xdg-user-dirs-update --set VIDEOS "$HOME/Videos"

### Theme
# Window Manager: Materia: https://github.com/nana-4/materia-theme
# Icons: Papirus: https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
if ! dpkg -s materia-gtk-theme &>/dev/null; then
    sudo apt-get install -y materia-gtk-theme
fi

if ! dpkg -s papirus-icon-theme &>/dev/null; then
    sudo add-apt-repository -y ppa:papirus/papirus
    sudo apt-get update
    sudo apt-get install -y papirus-icon-theme
fi

# For GTK3
gsettings set org.gnome.desktop.interface gtk-theme "Materia"
gsettings set org.gnome.desktop.wm.preferences theme "Materia"
# For GTK2
xfconf-query -c xsettings -p /Net/ThemeName -s "Materia"
xfconf-query -c xfwm4 -p /general/theme -s "Materia"

gsettings set org.gnome.desktop.interface icon-theme "Papirus"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus"

xfconf-query -c xsettings -p /Gtk/FontName -s "Noto Sans CJK SC 9"
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Noto Sans Mono CJK SC 9"
xfconf-query -c xfwm4 -p /general/title_font -s "Noto Sans CJK SC 9"

xfconf-query -c xfce4-notifyd -p /theme -s "Default"

### Free Download Manager
if [[ "$(wget -qO- "https://www.freedownloadmanager.org/board/viewtopic.php?f=1&t=17900" | grep -Po "([\d.]+)\s*\[\w+.*?STABLE" | head -n 1 | cut -f1 -d " ")" != "$(get_package_version freedownloadmanager)" ]]; then
    wget -O "$TMPDIR/freedownloadmanager.deb" https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb
    sudo gdebi -n "$TMPDIR/freedownloadmanager.deb"
fi
# I can't connect to freedownloadmanager apt repo, so remove it.
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
fi

### FSearch: https://github.com/cboxdoerfer/fsearch
if [[ -z "$(command -v fsearch)" ]]; then
    sudo add-apt-repository -y ppa:christian-boxdoerfer/fsearch-stable
    sudo apt-get update
    sudo apt-get install -y fsearch
fi

### Google Chrome: https://google.cn/chrome
if [[ -z "$(command -v google-chrome-stable)" ]]; then
    wget -O "$TMPDIR/google-chrome.deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo gdebi -n "$TMPDIR/google-chrome.deb"
fi

### Greenfish Icon Editor Pro
# TODO update
if ! dpkg -s gfie &>/dev/null; then
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
fi

### Microsoft Edge: https://www.microsoftedgeinsider.com/en-us/download/?platform=linux-deb
if [[ ! -f /etc/apt/sources.list.d/microsoft-edge.list ]]; then
    wget -O- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >"$TMPDIR/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$TMPDIR/microsoft.gpg" /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
    sudo apt-get update
fi
sudo apt-get install -y microsoft-edge-stable

### Onedriver: https://github.com/jstaf/onedriver
if [[ ! -f /etc/apt/sources.list.d/home:jstaf.list ]]; then
    echo "deb https://download.opensuse.org/repositories/home:/jstaf/xUbuntu_$(lsb_release -rs)/ /" | sudo tee /etc/apt/sources.list.d/home:jstaf.list
    wget -qO- "https://download.opensuse.org/repositories/home:jstaf/xUbuntu_$(lsb_release -rs)/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_jstaf.gpg >/dev/null
    sudo apt-get update
fi
sudo apt-get install -y onedriver

### Visual Studio Code: https://code.visualstudio.com/docs/setup/linux
if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
fi

### MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if [[ -z "$(command -v miktex)" ]]; then
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
fi

### Node
wget -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/https://raw.githubusercontent.com|g" -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | bash

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts

if ! grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
    echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
fi

touch "$HOME/.npmrc"
if ! grep -q "registry=" "$HOME/.npmrc"; then
    echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
fi

sudo chown -R 1000:1000 "$HOME/.npm"

# if [[ -z "$( command -v nativefier)" ]]; then
#     npm install -g nativefier
# fi

npm upgrade -g

### Prebuilt MPR 
# https://docs.makedeb.org/prebuilt-mpr/getting-started/
if [[ ! -e "/etc/apt/sources.list.d/prebuilt-mpr.list" ]]; then
    wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
    sudo apt-get update
fi

sudo apt-get install -y bat fd just ripgrep

### Sogou Pinyin
if [[ "$(lsb_release -rs)" == "20.04" ]]; then
    if [[ "$(wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | cut -f2 -d "_")" != "$(get_package_version sogoupinyin)" ]]; then
        wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | xargs wget -O "$TMPDIR/sogoupinyin.deb"
        sudo apt-get remove -y fcitx-ui-qimpanel
        sudo gdebi -n "$TMPDIR/sogoupinyin.deb"
        sudo apt-mark hold fcitx-ui-qimpanel
    fi
fi


### GitHub Releases apps
# install_github_releases_apps vercel/hyper hyper amd64.deb
install_github_releases_apps dbeaver/dbeaver dbeaver-ce amd64.deb
install_github_releases_apps Figma-Linux/figma-linux figma-linux .amd64.deb
install_github_releases_apps flameshot-org/flameshot flameshot "ubuntu-$(lsb_release -rs).amd64.deb"
install_github_releases_apps jgm/pandoc pandoc amd64.deb
install_github_releases_apps jgraph/drawio-desktop draw.io .deb
install_github_releases_apps localsend/localsend localsend .deb
install_github_releases_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb
install_github_releases_apps OpenBoard-org/OpenBoard openboard "$(lsb_release -rs)_.*_amd64.deb"
install_github_releases_apps peazip/PeaZip peazip .GTK2-1_amd64.deb
install_github_releases_apps shiftkey/desktop github-desktop .deb
install_github_releases_apps Zettlr/Zettlr zettlr amd64.deb

### GitHub Releases AppImage apps
# Joplin
install_appimage_apps laurent22/joplin joplin
if [[ ! -e "$HOME/.local/share/icons/hicolor/512x512/apps/joplin.png" ]]; then
    wget -O "$TMPDIR/joplin.png" https://joplinapp.org/images/Icon512.png
    sudo mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
    sudo mv "$TMPDIR/joplin.png" "$HOME/.local/share/icons/hicolor/512x512/apps"
fi

mkdir -p "$HOME/.local/share/applications"
cat <<EOF | sudo tee "$HOME/.local/share/applications/joplin.desktop"
[Desktop Entry]
Encoding=UTF-8
Name=Joplin
Comment=Joplin for Desktop
Exec=$HOME/.AppImageApplications/joplin.AppImage %u
Icon=joplin
StartupWMClass=Joplin
Type=Application
Categories=Office;
MimeType=x-scheme-handler/joplin;
X-GNOME-SingleWindow=true
SingleMainWindow=true
EOF

# Losslesscut
install_appimage_apps mifi/lossless-cut losslesscut
if [[ ! -e "$HOME/.local/share/icons/hicolor/scalable/apps/losslesscut.svg" ]]; then
    wget -O "$TMPDIR/losslesscut.svg" https://ghproxy.com/https://github.com/mifi/lossless-cut/raw/master/src/icon.svg
    sudo mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
    sudo mv "$TMPDIR/losslesscut.svg" "$HOME/.local/share/icons/hicolor/scalable/apps"
fi

mkdir -p "$HOME/.local/share/applications"
wget -O "$TMPDIR/losslesscut.desktop" https://ghproxy.com/https://github.com/mifi/lossless-cut/raw/master/no.mifi.losslesscut.desktop
sudo mv "$TMPDIR/losslesscut.desktop" "$HOME/.local/share/applications/losslesscut.desktop"
sudo sed -i -e "s|Exec=.*|Exec=$HOME/.AppImageApplications/losslesscut.AppImage %u|g" "$HOME/.local/share/applications/losslesscut.desktop"

update-desktop-database "$HOME/.local/share/applications"

### Tor Browser
TOR_BROWSER_LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/TheTorProject/gettorbrowser/releases/latest" | jq -r ".tag_name" | sed "s/.*-//g")

if [[ -e "$HOME/.tor-browser/VERSION" ]]; then
    TOR_BROWSER_INSTALLED_VERSION=$(cat "$HOME/.tor-browser/VERSION")
else
    TOR_BROWSER_INSTALLED_VERSION=not_installed
fi

if [[ "$TOR_BROWSER_INSTALLED_VERSION" != "$TOR_BROWSER_LATEST_VERSION" ]]; then
    wget -O "$TMPDIR/tor-browser.tar.xz" "https://ghproxy.com/https://github.com/TheTorProject/gettorbrowser/releases/download/linux64-${TOR_BROWSER_LATEST_VERSION}/tor-browser-linux64-${TOR_BROWSER_LATEST_VERSION}_ALL.tar.xz"

    # Remove old version.
    if [[ -f "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" ]]; then
        "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --unregister-app
    fi
    [[ -d "$HOME/.tor-browser/tor-browser" ]] && rm -rf "$HOME/.tor-browser/tor-browser"

    # Install new version.
    mkdir -p "$HOME/.tor-browser"
    tar --extract --xz --directory "$HOME/.tor-browser" --file "$TMPDIR/tor-browser.tar.xz"
    "$HOME/.tor-browser/tor-browser/Browser/start-tor-browser" --register-app

    # Record version
    echo "$TOR_BROWSER_LATEST_VERSION" >"$HOME/.tor-browser/VERSION"
fi

### GVim
sudo apt-get install -y vim vim-gtk

mkdir -p "$HOME/.vim/autoload"
if [[ ! -f "$HOME/.vim/autoload/pathogen.vim" ]]; then
    wget -O "$HOME/.vim/autoload/pathogen.vim" https://ghproxy.com/https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim
fi

install_vim_plugin yianwillis/vimcdoc
install_vim_plugin sheerun/vim-polyglot
install_vim_plugin vim-airline/vim-airline
install_vim_plugin dracula/vim

# vimrc
cat <<EOF >"$HOME/.vimrc"
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
source \$VIMRUNTIME/delmenu.vim
source \$VIMRUNTIME/menu.vim
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

### WPS Office https://linux.wps.cn/
if [[ "$(wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb" | cut -f2 -d "_")" != "$(get_package_version wps-office)" ]]; then
    wget -qO- https://linux.wps.cn/ | grep -Po "https://.*amd64\.deb" | xargs wget -O "$TMPDIR/wps-office.deb"
    sudo gdebi -n "$TMPDIR/wps-office.deb"
fi

# WPS needs to install symbol fonts.
if [[ ! -f /usr/share/fonts/wps-fonts/mtextra.ttf ]] || [[ ! -f /usr/share/fonts/wps-fonts/symbol.ttf ]] || [[ ! -f /usr/share/fonts/wps-fonts/WEBDINGS.TTF ]] || [[ ! -f /usr/share/fonts/wps-fonts/wingding.ttf ]] || [[ ! -f /usr/share/fonts/wps-fonts/WINGDNG2.ttf ]] || [[ ! -f /usr/share/fonts/wps-fonts/WINGDNG3.ttf ]]; then
    sudo mkdir -p /usr/share/fonts/wps-fonts
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/mtextra.ttf
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/symbol.ttf
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WEBDINGS.TTF
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/wingding.ttf
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WINGDNG2.ttf
    wget -P "$TMPDIR/wps-fonts" https://ghproxy.com/https://github.com/BannedPatriot/ttf-wps-fonts/raw/master/WINGDNG3.ttf
    sudo rm -rf /usr/share/fonts/wps-fonts
    sudo cp -rf "$TMPDIR/wps-fonts" /usr/share/fonts
    sudo chmod 644 /usr/share/fonts/wps-fonts/*
    sudo fc-cache -fs
fi


# for FILE in "$SCRIPT_DIR"/install/*.sh; do
#     # shellcheck source=/dev/null
#     . "$FILE"
# done

### Extras
sudo apt-get install -y android-sdk-platform-tools aria2 audacity calibre digikam filezilla ffmpeg freecad ghostscript gimp handbrake imagemagick inkscape libvips-tools mupdf mupdf-tools neofetch network-manager-openvpn-gnome obs-studio openjdk-11-jre openvpn pdfarranger plank proxychains4 scrcpy scribus shotcut sigil subversion vlc wkhtmltopdf xfce4-appmenu-plugin xfce4-clipman-plugin
# autostart
if [[ ! -e /etc/xdg/autostart/plank.desktop ]]; then
    sudo cp -f /usr/share/applications/plank.desktop /etc/xdg/autostart
fi

mkdir -p "$HOME/.config/autostart"
if [[ ! -e "$HOME/.config/autostart/start-tor-browser.desktop" ]]; then
    cp -f "$HOME/.local/share/applications/start-tor-browser.desktop" "$HOME/.config/autostart"
fi


echo "Uninstalling unnecessary apps..."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Remove LibreOffice, use WPS Office instead.
# sudo apt purge --autoremove libreoffice*

echo "Checking installed apps' update..."
sudo apt-get upgrade -y

# Used for Ventoy VDisk boot
if [[ "$VTOYBOOT" == "true" ]]; then
    VTOY_LATEST_VERSION=$(wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".tag_name" | tr -d "v")
    
    if [[ -e "$HOME/.vtoyboot/VERSION" ]]; then
        VTOY_INSTALLED_VERSION=$(cat "$HOME/.vtoyboot/VERSION")
    else
        VTOY_INSTALLED_VERSION=not_installed
    fi

    if [[ "$VTOY_INSTALLED_VERSION" != "$VTOY_LATEST_VERSION" ]]; then
        # Remove old version.
        [[ -d "$HOME/.vtoyboot" ]] && rm -rf "$HOME/.vtoyboot"

        # Install new version.
        wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/ventoy/vtoyboot/releases/latest | jq -r ".assets[].browser_download_url" | grep .iso | head -n 1 | sed -e "s|https://github.com|https://ghproxy.com/github.com|g" | xargs wget -O "$TMPDIR/vtoyboot.iso"

        7z x -o"$TMPDIR" "$TMPDIR/vtoyboot.iso"
        mkdir -p "$HOME/.vtoyboot"
        tar --extract --gz --directory "$HOME/.vtoyboot" --file "$TMPDIR/vtoyboot-$VTOY_LATEST_VERSION.tar.gz"

        # Record version.
        echo "$VTOY_LATEST_VERSION" >"$HOME/.vtoyboot/VERSION"
    fi

    cd "$HOME/.vtoyboot/vtoyboot-$VTOY_LATEST_VERSION" || exit 1
    sudo bash "./vtoyboot.sh"
    cd "$OLDPWD" || exit 1
    echo "Completed!" && exit 0
fi
