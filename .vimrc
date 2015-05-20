" ========================================================================
" First use
"   $ mkdir -p ~/.vim/autoload ~/.vim/bundle
"   $ curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
"   $ git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
"   $ sudo apt-get install exuberant-ctags
"   $ mkdir ~/.tmp
"   
" Then open vim and run the command
"   :BundleInstall
"
" If using PuTTY, Ctrl-S is mapped to XOFF (no terminal output).
" Disable this by adding those lines in your ~/.bashrc:
" stty ixany
" stty ixoff -ixon
" stty stop undef
" stty start undef
" ========================================================================

" Use Pathogen to load bundles
execute pathogen#infect()

" ========================================================================
" Vundle stuff (manage Vim plugins)
" ========================================================================
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Let Vundle manage Vundle (required)!
Bundle 'gmarik/vundle'

" My bundles
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-sensible'
Bundle 'tpope/vim-scriptease'
Bundle 'tpope/vim-rails'
Bundle 'tpope/vim-bundler'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-commentary'
Bundle 'tpope/vim-sleuth'
Bundle 'tpope/vim-repeat'
Bundle 'tpope/vim-haml'
Bundle 'tpope/vim-vividchalk'
Bundle 'slim-template/vim-slim'
Bundle 'genoma/vim-less'
Bundle 'ervandew/supertab'
Bundle 'scrooloose/nerdtree'

" ================
" Ruby stuff
" ================
syntax on
filetype plugin indent on
set number

" From Ben Orenstein
augroup myfiletypes
  " Clear old autocmds in group
  autocmd!
  " autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et
augroup END

" Handy shortcuts
let mapleader = ","
map <Leader>vi :tabe ~/.vimrc<CR>
nmap <Leader>bi :source ~/.vimrc<cr>:BundleInstall<cr>
" Navigation
map <Leader>sm :RSmodel 
map <Leader>sv :RSview 
map <Leader>sc :RScontroller 
map <Leader>vm :RVmodel 
map <Leader>vv :RVview 
map <Leader>vc :RVcontroller 
map <Leader>rm :RTmodel 
map <Leader>rv :RTview 
map <Leader>rc :RTcontroller 
map <Leader>ra :%s/
map <Leader>sk :tabe db/schema.rb<cr>
map <Leader>fa :tabe spec/factories.rb<CR>
map <Leader>rt :tabe config/routes.rb<CR>
map <Leader>gm :tabe Gemfile<CR>
map <Leader>en :tabe config/locales/en.yml<CR>
map <Leader>fr :tabe config/locales/fr.yml<CR>
map <Leader>ab :tabe app/models/ability.rb<CR>
map <Leader>nt :NERDTree<CR>
map <Leader>rr :!rake routes \| grep<Space>
nnoremap <Tab> <C-w>w
nnoremap <S-Tab> <C-w>k
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
noremap <C-H> <C-W><C-H>
" <C-w> _   --> Max out the height of the current split
" <C-w> |   --> Max out the width of the current split
" <C-w> =   --> Normalize all split sizes, which is very handy when resizing
" 10 <C-w> >   --> Extend the current vertical buffer by 10 chars to the left
" 10 <C-w> <   --> Extend the current vertical buffer by 10 chars to the right
" 10 <C-w> -   --> Extend the current horizontal buffer by 10 chars to the top
" 10 <C-w> +   --> Extend the current horizontal buffer by 10 chars to the bottom
" <C-w> R   --> Swap top/bottom or left/right split
" <C-w> T   --> Break out current window into a new tabview
" <C-w> o   --> Close every window in the current tabview but the current one
map - <C-w>-
map + <C-w>+

" Easier on Mac
map := :!
" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path
map <Leader>e :e <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>s :split <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>v :vnew <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>t :tabe <C-R>=expand("%:p:h") . '/'<CR>
" Tests
map <Leader>tp :!rake db:test:prepare<CR>
map <Leader>te :w<cr>:!rspec % --format documentation --tag ~js<CR>
map <Leader>tr :w<cr>:!rspec % --tag ~js<CR>
map <Leader>ta :w<cr>:!rspec spec --tag ~js<CR>
map <Leader>tz :w<cr>:!rspec spec -fd --tag ~js<CR>
map <Leader>ts :w<cr>:!rspec spec<CR>
map <Leader>tt :w<cr>:!rspec fast_spec<CR>
map <Leader>tm :w<cr>:!rspec spec/models<CR>
map <Leader>tc :w<cr>:!rspec spec/controllers<CR>
map <Leader>tf :w<cr>:!rspec spec/features<CR>
map <Leader>sj :w<cr>:call OpenJasmineSpecInBrowser()<cr>
" Bundle
map <Leader>bb :!bundle install<CR>
" Git
map <Leader>gd :!git diff<CR>
map <Leader>gs :!git status<CR>
map <Leader>gr :!git grep<Space>
" CTags
" F9: open preview
" F5: close preview
" F10: open tag in current tab
" F11: open tag in horizontal split
" F12: open tag in new tab
" Delete: back to previous location
map <F9> <C-w>}
map <F5> <C-w>z
map <F10> <C-]>
map <F11> <C-W>]
map <F12> <C-w><C-]><C-w>T
map <BS> <C-o>
map ga :A<CR>
map gr :R<CR>
map <Leader>gt <C-]>
map <Leader>gg <C-T>
map <Leader>ct :!ctags -R --exclude=.git --exclude=log --exclude=*.js --exclude=*.css *<CR>
" Search and replace
map <Leader>rw :%s/\s\+$//<cr>:w<cr>
map <Leader>vg :vsp<cr>:grep 
" Maps auto-complete to tab
imap <Tab> <C-N>
imap <C-L> <Space>=><Space>
" Indent current file
map <Leader>i mmgg=G`m<CR>
map <Leader>j :%s/\t/  /<CR>
" Auto-close HTML tags when typing <//
iabbrev <// </<C-X><C-O>
" Auto-open ERB tags
map <Leader>< i<% %><esc>hhi
" Move up and down within a long wrapped line
nmap k gk
nmap j gj
" Dropbox
map <Leader>dn :tabe ~/Dropbox/Rails/rails-freelance-neocamino.txt<cr>
" Other
map <Leader>co ggVG"*y
map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>
map <C-s> <esc>:w<CR>
imap <C-s> <esc>:w<CR>
map <C-t> <esc>:tabnew<CR>
map <F4> :q!<CR>

" Color scheme
colorscheme vividchalk
highlight NonText guibg=#060606
highlight Folded  guibg=#0A0A0A guifg=#9090D0

" Tab completion options
" (only complete to the longest unambiguous match, and show a menu)
:highlight PmenuSel ctermfg=black
set completeopt=longest,menu
set wildmode=list:longest,list:full
set complete=.,t

set ignorecase smartcase " case only matters with mixed case expressions
"set relativenumber " show relative line numbers (needs recent vim)
set tags=./tags; " Set the tag file search order
set backupdir=~/.tmp " Don't clutter my dirs up with swp and tmp files
set directory=~/.tmp
set gdefault " Assume the /g flag on :s substitutions to replace all matches in a line
set formatoptions-=or " Don't add the comment prefix when I hit enter or o/O on a comment line.
set pastetoggle=<F2> " Toggle paste/nopaste to avoid auto-indent when pasting code

" %% is the current path
cabbr <expr> %% expand('%:p:h')

" Show trailing white spaces
:highlight ExtraWhitespace ctermbg=red guibg=red
:match ExtraWhitespace /\s\+$/

" Fuzzy finder: ignore stuff that can't be opened, and generated files
let g:fuzzy_ignore = "*.png;*.PNG;*.JPG;*.jpg;*.GIF;*.gif;vendor/**;coverage/**;tmp/**;rdoc/**"

" Highlight the status line
highlight StatusLine ctermfg=blue ctermbg=yellow

" Hightlight style
highlight def link rubyFunction Function

" When loading text files, wrap them and don't split up words.
au BufNewFile,BufRead *.txt setlocal wrap 
au BufNewFile,BufRead *.txt setlocal lbr

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RENAME CURRENT FILE (thanks Gary Bernhardt)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'), 'file')
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
  endif
endfunction
map <Leader>n :call RenameFile()<cr>
