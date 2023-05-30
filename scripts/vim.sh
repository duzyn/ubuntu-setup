#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

log "Installing Vim GTK…"
sudo apt-get install -y vim vim-gtk

# Usage: install_vim_plugin repo/name
function install_vim_plugin() {
    local REPO_NAME PLUGIN_NAME
    REPO_NAME=$1
    PLUGIN_NAME="$(basename "$REPO_NAME")"

    [[ -d "$HOME/.vim/pack/plugins/start" ]] || mkdir -p "$HOME/.vim/pack/plugins/start"
    if [[ -d "$HOME/.vim/pack/plugins/start/$PLUGIN_NAME" ]]; then
        cd "$HOME/.vim/pack/plugins/start/$PLUGIN_NAME" || exit
        log "Updating Vim plugin $REPO_NAME..."
        git pull
    else
        log "Installing Vim plugin $REPO_NAME..."
        git clone --depth 1 "https://ghproxy.com/https://github.com/$REPO_NAME" "$HOME/.vim/pack/plugins/start/$PLUGIN_NAME"
    fi
}

install_vim_plugin yianwillis/vimcdoc
install_vim_plugin sheerun/vim-polyglot
install_vim_plugin vim-airline/vim-airline

# vimrc
cat <<EOF >"$HOME/.vimrc"
syntax on

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
EOF