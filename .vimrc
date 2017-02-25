set nocompatible              " be iMproved, required
filetype off                  " required

filetype plugin indent on     " required

call plug#begin('~/.local/share/nvim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim'
Plug 'chrisbra/Colorizer'
Plug 'scrooloose/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/syntastic'
Plug 'kien/ctrlp.vim'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer --gocode-completer' }
Plug 'tpope/vim-surround'
Plug 'wikitopian/hardmode'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'fatih/vim-go'
Plug 'vim-ruby/vim-ruby'
Plug 'elzr/vim-json'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

call plug#end()                 " required

"
" ==================== Settings ====================
"

set noerrorbells                " No beeps
set number                      " Show line numbers
set backspace=indent,eol,start  " Makes backspace key more powerful.
set showcmd                     " Show me what I'm typing
set showmode                    " Show current mode.

"set noswapfile                 " Don't use swapfile
"set nobackup                   " Don't create annoying backup files
"set nowritebackup
set splitright                  " Split vertical windows right to the current windows
set splitbelow                  " Split horizontal windows below to the current windows
set encoding=utf-8              " Set default encoding to UTF-8
set autowrite                   " Automatically save before :next, :make etc.
set autoread                    " Automatically reread changed files without asking me anything
set laststatus=2                " Always display the statusline in all windows
set showtabline=2               " Always display the tabline, even if there is only one tab
set hidden

set ruler                       " Show the cursor position all the time
au FocusLost * :wa              " Set vim to save the file on focus out.

set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats

set noshowmatch                 " Do not show matching brackets by flickering
set noshowmode                  " We show the mode with airline or lightline
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not when search pattern contains upper case characters
set ttyfast
" set ttyscroll=3                 " noop on linux ?
set lazyredraw                  " Wait to redraw "

" Speed up syntax highlighting
set nocursorcolumn
set nocursorline

syntax sync minlines=256
set synmaxcol=300
set re=1

" Open help vertically
command! -nargs=* -complete=help Help vertical belowright help <args>
autocmd FileType help wincmd L

set formatoptions=qrn1
set relativenumber

set et
set tabstop=4
set shiftwidth=4
set expandtab

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
    set mouse=a
endif

" If linux then set ttymouse
let s:uname = system("echo -n \"$(uname)\"")
if !v:shell_error && s:uname == "Linux" && !has('nvim')
    set ttymouse=xterm
endif

" Remove highlighting with Ctrl+L
" This should also reload the buffer
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

" Do not show stupid q: window
map q: :q

" Allow saving of files as sudo when I forgot to start vim using sudo.
cmap w!! w !sudo tee > /dev/null %

" List chars with unicode
exec "set listchars=tab:\uBB\uBB,trail:\uB7,nbsp:~"

" Visual indication for long lines
"set colorcolumn=91
" But only show it when the line is actually long.
highlight ColorColumn ctermbg=red
call matchadd('ColorColumn', '\%91v', 100)

" When typing jj in insert mode, go back to normal mode
inoremap jj <ESC>

" Use :w!! to write to a file using sudo if you forgot to 'sudo vim file'
" (it will prompt for sudo password when writing)
cmap w!! %!sudo tee > /dev/null %

" Toggle hlsearch with <leader>hs
nmap <leader>hs :set hlsearch! hlsearch?<CR>

" Open any file with pre-existing swapfile in readonly mode
augroup NoSimultaneousEdits
    autocmd!
    autocmd SwapExists * let v:swapchoice = 'o'
    autocmd SwapExists * echomsg ErrorMsg
    autocmd SwapExists * echo 'Duplicate edit session (readonly)'
    autocmd SwapExists * echohl None
    autocmd SwapExists * sleep 2
augroup END

" ----------------------------------------- "
" Plugin config                             "
" ----------------------------------------- "

" ==================== Vim-Markdown ====================

let g:vim_markdown_no_default_key_mappings = 1
let g:vim_markdown_math = 1
let g:vim_markdown_folding_disabled = 1

" ==================== Vim-go ====================
let g:go_fmt_fail_silently = 0
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_term_enabled = 1
let g:go_snippet_engine = "neosnippet"
let g:go_highlight_space_tab_error = 0
let g:go_highlight_array_whitespace_error = 0
let g:go_highlight_trailing_whitespace_error = 0
let g:go_highlight_extra_types = 0
let g:go_highlight_operators = 0
let g:go_highlight_build_constraints = 1

au FileType go nmap <Leader>s <Plug>(go-def-split)
au FileType go nmap <Leader>v <Plug>(go-def-vertical)
au FileType go nmap <Leader>i <Plug>(go-info)
au FileType go nmap <Leader>l <Plug>(go-metalinter)

au FileType go nmap <leader>r  <Plug>(go-run)

au FileType go nmap <leader>b  <Plug>(go-build)
au FileType go nmap <leader>t  <Plug>(go-test)
au FileType go nmap <leader>dt  <Plug>(go-test-compile)
au FileType go nmap <Leader>d <Plug>(go-doc)

" I like these more!
augroup go
    autocmd!
    autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
    autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
    autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
augroup END

" ==================== NerdTree ====================
" For toggling
nmap <C-n> :NERDTreeToggle<CR>
noremap <Leader>n :NERDTreeToggle<cr>
noremap <Leader>f :NERDTreeFind<cr>

let NERDTreeShowHidden=1

let NERDTreeIgnore=['\.vim$', '\~$', '\.git$', '.DS_Store']

" Close nerdtree and vim on close file
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" ==================== vim-airline ====================
let g:airline_theme='dracula'
let g:airline_powerline_fonts=1
"
" Tabbar customization
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
