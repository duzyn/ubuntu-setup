#!/usr/bin/env bash

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

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y vim vim-gtk

mkdir -p "$HOME/.vim/autoload"
if [[ ! -f "$HOME/.vim/autoload/pathogen.vim" ]]; then
    wget -O "$HOME/.vim/autoload/pathogen.vim" \
        https://ghproxy.com/https://github.com/tpope/vim-pathogen/raw/master/autoload/pathogen.vim
fi

# Install vim plugin
mkdir -p "$HOME/.vim/bundle"
git clone --depth 1 "https://ghproxy.com/https://github.com/yianwillis/vimcdoc" "$HOME/.vim/bundle/vimcdoc"
git clone --depth 1 "https://ghproxy.com/https://github.com/sheerun/vim-polyglot" "$HOME/.vim/bundle/vim-polyglot"
git clone --depth 1 "https://ghproxy.com/https://github.com/vim-airline/vim-airline" "$HOME/.vim/bundle/vim-airline"
git clone --depth 1 "https://ghproxy.com/https://github.com/dracula/vim" "$HOME/.vim/bundle/vim-dracula"

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