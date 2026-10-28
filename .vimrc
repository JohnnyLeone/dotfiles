" Shared Vimscript settings, primarily used by Neovim.
filetype plugin indent on

if !has('nvim') && isdirectory(expand('~/.local/share/nvim/site'))
  set runtimepath+=~/.local/share/nvim/site
endif

" Start cleanly even before optional plugins have been installed.
if !empty(globpath(&runtimepath, 'autoload/plug.vim'))
call plug#begin('~/.local/share/nvim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'chrisbra/Colorizer'
Plug 'preservim/nerdtree'
Plug 'preservim/tagbar'
Plug 'easymotion/vim-easymotion'
Plug 'preservim/nerdcommenter'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tpope/vim-surround'
Plug 'takac/vim-hardtime'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'fatih/vim-go'
Plug 'vim-ruby/vim-ruby'
Plug 'elzr/vim-json'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'jamessan/vim-gnupg'
if has('nvim')
  Plug 'jake-stewart/multicursor.nvim', { 'branch': '1.0' }
endif
Plug 'reedes/vim-pencil'
Plug 'dpelle/vim-LanguageTool'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
if has('python3')
  Plug 'SirVer/ultisnips'
  Plug 'honza/vim-snippets'
endif
call plug#end()                 " required
endif

"
" ===================== Settings ======================
"

set noerrorbells                " No beeps
set number                      " Show line numbers
set backspace=indent,eol,start  " Makes backspace key more powerful.
set showcmd                     " Show me what I'm typing
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

set fileformats=unix,dos

set noshowmatch                 " Do not show matching brackets by flickering
set noshowmode                  " We show the mode with airline or lightline
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not when search pattern contains upper case characters

" Speed up syntax highlighting
set nocursorcolumn
set nocursorline

syntax sync minlines=256
set synmaxcol=300

" Open help vertically
command! -nargs=* -complete=help Help vertical belowright help <args>
autocmd FileType help wincmd L

set formatoptions=qrn1
set relativenumber

set tabstop=4
set shiftwidth=4
set expandtab

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
    set mouse=a
endif

" Do not show stupid q: window
map q: :q

" This comes first, because we have mappings that depend on leader
" With a map leader it's possible to do extra key combinations
" i.e: <leader>w saves the current file
let mapleader = ","

" List chars with unicode
exec "set listchars=tab:\uBB\uBB,trail:\uB7,nbsp:~"

" Visual indication for long lines
" But only show it when the line is actually long.
highlight ColorColumn ctermbg=red
call matchadd('ColorColumn', '\%91v', 100)

" When typing jj in insert mode, go back to normal mode
inoremap jj <ESC>

" Use :w!! to write to a file using sudo if you forgot to 'sudo vim file'
" (it will prompt for sudo password when writing)
cmap w!! %!sudo tee > /dev/null %

" Toggle hlsearch with <leader>hl
nmap <leader>hl :set hlsearch! hlsearch?<CR>

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

" =================== Vim-Markdown ====================

let g:vim_markdown_no_default_key_mappings = 1
let g:vim_markdown_math = 1
let g:vim_markdown_folding_disabled = 1

" ====================== Vim-go =======================
let g:go_fmt_fail_silently = 0
let g:go_fmt_command = "goimports"
let g:go_term_enabled = 1
let g:go_snippet_engine = "ultisnips"
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

au FileType go nmap <Leader>e <Plug>(go-rename)

" neovim specific
if has('nvim')
  au FileType go nmap <leader>rt <Plug>(go-run-tab)
  au FileType go nmap <Leader>rs <Plug>(go-run-split)
  au FileType go nmap <Leader>rv <Plug>(go-run-vertical)
endif

" I like these more!
augroup go
  autocmd!
  autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
  autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
  autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
augroup END

" ===================== NerdTree ======================
" For toggling
if isdirectory(expand('~/.local/share/nvim/plugged/nerdtree'))
  nnoremap <C-n> :NERDTreeToggle<CR>
  nnoremap <Leader>n :NERDTreeToggle<CR>
  nnoremap <Leader>f :NERDTreeFind<CR>
else
  nnoremap <C-n> :Lexplore<CR>
  nnoremap <Leader>n :Lexplore<CR>
  nnoremap <Leader>f :Explore<CR>
endif

let NERDTreeShowHidden=1

let NERDTreeIgnore=['\.vim$', '\~$', '\.git$', '.DS_Store']

" Close nerdtree and vim on close file
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

" ===================== vim-json ======================
let g:vim_json_syntax_conceal = 0

" ===================== Completion ====================
" Built-in completion works without the retired deoplete/Python host stack.
set completeopt=menu,menuone,noselect

" ==================== Multiple selections ====================
" Preserve selection shortcuts without taking NERDTree's Ctrl+n mapping.
if has('nvim')
lua << EOF
local ok, mc = pcall(require, 'multicursor-nvim')
if ok then
  mc.setup()
  vim.keymap.set({'n', 'x'}, '<C-i>', function() mc.matchAddCursor(1) end)
  mc.addKeymapLayer(function(set)
    set({'n', 'x'}, '<C-y>', function() mc.matchAddCursor(-1) end)
    set({'n', 'x'}, '<C-b>', function() mc.matchSkipCursor(1) end)
    set('n', '<Esc>', mc.clearCursors)
  end)
end
EOF
endif

" ================== NerdCommenter ====================
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" ==================== vim-pencil =====================
augroup pencil
  autocmd!
  autocmd FileType markdown,mkd if !empty(globpath(&runtimepath, 'autoload/pencil.vim')) | call pencil#init() | endif
  autocmd FileType text if !empty(globpath(&runtimepath, 'autoload/pencil.vim')) | call pencil#init() | endif
augroup END

" ==================== UltiSnips ======================
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<c-b>"
let g:UltiSnipsJumpBackwardTrigger = "<c-z>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit = "vertical"

" ==================== vim-airline ====================
let g:airline_theme = 'dracula'
let g:airline_powerline_fonts = 1

if !empty(globpath(&runtimepath, 'colors/dracula.vim'))
  colorscheme dracula
endif

" Tabbar customization
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

