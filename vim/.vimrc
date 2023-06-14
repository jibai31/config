set nocompatible              " be iMproved, required
filetype on                   " required for compatibility with Mac OS X, See issue #167
filetype off                  " required
filetype plugin indent on     " required

" ========================================================================
" VIM FIRST SETUP
" ========================================================================
" Setup external dependencies and create temp folder:
"
"   $ sudo apt-get install exuberant-ctags
"   $ mkdir ~/.tmp
"
" Plugins are managed with Vim 8 plugin manager
" Simply place plugins to ~/.vim/pack/**/start
"
"   $ mkdir -p ~/.vim/pack/tpope/start
"   $ cd ~/.vim/pack/tpope/start
"   $ git clone https://tpope.io/vim/dispatch.git
"
" If using PuTTY, Ctrl-S is mapped to XOFF (no terminal output).
" Disable this by adding those lines in your ~/.bashrc:
" stty ixany
" stty ixoff -ixon
" stty stop undef
" stty start undef
" ========================================================================

" ========================================================================
" NEOVIM SETUP
" ========================================================================
"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
"If you're using tmux version 2.2 or later,
"you can remove the outermost $TMUX check and use tmux's 24-bit color support
"(see < http://sunaku.github.io/tmux-24bit-color.html#usage > for more information.)
if (empty($TMUX))
  if (has("nvim"))
    "For Neovim 0.1.3 and 0.1.4
    "https://github.com/neovim/neovim/pull/2198
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  "For Neovim > 0.1.5 and Vim > patch 7.4.1799
  "  https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162
  "Based on Vim patch 7.4.1770 (`guicolors` option)
  "  https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd
  "  https://github.com/neovim/neovim/wiki/Following-HEAD#20160511
  if (has("termguicolors"))
    set termguicolors
  endif
endif


" ========================================================================
" NEOVIM PLUGINS
" ========================================================================
"
" Install vim-plug
"
"   $ sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
"      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
"
" Install all plugins below
"
"   :PlugInstall
"
" Also need following tools
"
"   brew install ripgrep
"
" ========================================================================
call plug#begin('~/.config/nvim/plugged')
let g:plug_url_format = 'git@github.com:%s.git'
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-vividchalk'
Plug 'tpope/vim-sensible'
Plug 'numToStr/Comment.nvim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
call plug#end()


" ================
" Ruby stuff
" ================
syntax on
set number
set redrawtime=10000

" From Ben Orenstein
augroup myfiletypes
  " Clear old autocmds in group
  autocmd!
  " autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et
augroup END

" Handy shortcuts
let mapleader = ","
nmap <Leader>bi :source ~/.vimrc<cr>
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
map <Leader>nt :NERDTree<CR>
map <Leader>rr :!bin/rake routes \| grep<Space>
map <Leader>lm :Smigration<CR>
map <Leader>lt :sp lib/tasks/
nnoremap <Tab> <C-w>w
nnoremap <S-Tab> <C-w>k
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" <C-w> _   --> Max out the height of the current split
" <C-w> |   --> Max out the width of the current split
" <C-w> =   --> Normalize all split sizes, which is very handy when resizing
" 10 <C-w> >   --> Extend the current vertical buffer by 10 chars to the left
" 10 <C-w> <   --> Extend the current vertical buffer by 10 chars to the right
" 10 <C-w> -   --> Extend the current horizontal buffer by 10 chars to the top
" 10 <C-w> +   --> Extend the current horizontal buffer by 10 chars to the bottom
" <C-w> R   --> Switch/Swap top/bottom or left/right split
" <C-w> T   --> Break out current window into a new tabview
" <C-w> o   --> Close every window in the current tabview but the current one
map - <C-w>-
map + <C-w>+
map _ <C-w>_
map = <C-w>=
map zz :set foldmethod=indent<CR>:syntax on<CR>
map <Space> z.

" Easier on Mac
map := :!
" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path
map <Leader>e :e <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>s :split <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>v :vnew <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>t :tabe <C-R>=expand("%:p:h") . '/'<CR>

" Vim Surround: https://github.com/tpope/vim-surround
" cs"'     Replaces surrounding double quotes with single quotes
" cs'<p>   Now with <p></p>
" cst"     Now back to double quotes
" ds"      Removes the quotes
" ysiw<em> For just the current word (iw = text object)

" CtrlP to find files
map <Leader>f :CtrlPMixed<CR>
let g:ctrlp_cmd = 'CtrlPMixed'
" <c-p>   Start normal mode
" <c-t>   Open the selected file in a new 'tab'.
" <c-v>   Open the selected file in a 'vertical' split.
" <c-x>, <c-cr>, <c-s> Open the selected file in a 'horizontal' split.
" Search '_navigation:45' Open at line 45
" <c-f> and <c-b> to cycle between modes
" <F5> to purge the cache for the current directory to get new files, remove
" deleted files and apply new ignore option

" Tests
map <Leader>tt :w<cr>:call RSpecCurrent()<CR>
map <Leader>tr :w<cr>:!bin/rspec % --tag ~js<CR>
map <Leader>te :w<cr>:!bin/rspec % --format documentation --tag ~js<CR>
map <Leader>tz :w<cr>:!bin/rspec spec --tag ~js<CR>
map <Leader>ta :w<cr>:!bin/rspec spec -fd --tag ~js<CR>
map <Leader>tm :w<cr>:!bin/rspec spec/models<CR>
map <Leader>tf :w<cr>:!bin/rspec spec/features<CR>
" Bundle
map <Leader>bb :!bundle install<CR>
" Git
map <Leader>gd :!git diff<CR>
map <Leader>gs :!git status<CR>
"map <Leader>gr :!git grep<Space>
map <Leader>gr :!Rg<Space>
nnoremap K :Ggrep <C-R><C-W><CR>:cw<CR><CR>
" CTags
" F9: open preview
" F5: close preview
" F6: move tab to new window
" F7: open tag in vertical split
" F8: open tag in horizontal split (when F11 doesn't work)
" F10: open tag in current tab
" F11: open tag in horizontal split
" F12: open tag in new tab
" Delete: back to previous location
map <F9> <C-w>}
map <F5> <C-w>z
map <F6> <C-w>T
map <F7> <C-w><C-]><C-w>L
map <F8> <C-w>f
map <F10> <C-]>
map <F11> <C-W>]
map <F12> <C-w><C-]><C-w>T
map <BS> <C-o>
map ga :A<CR>
map gr :R<CR>
map <Leader>gt <C-]>
map <Leader>gg <C-T>
map <Leader>ct :!ctags -R<CR>
" Search and replace
map <Leader>rw :%s/\s\+$//<cr>:w<cr>
map <Leader>vg :vsp<cr>:grep
nmap ù *
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
" Other
map <Leader>co ggVG"*y
map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>
map s :w<CR>
map <C-s> <esc>:w<CR>
imap <C-s> <esc>:w<CR>
map <C-t> <esc>:tabnew<CR>
map <F4> :q!<CR>
map :ws :w !sudo tee %<CR>
map <Leader>nn :set nonumber<CR>
map <Leader>ni :set number<CR>

" Color scheme
" syntax enable
" set background=dark
" colorscheme distinguished
" colorscheme candy
colorscheme vividchalk
" colorscheme gruvbox
" colorscheme railscasts
" colorscheme solarized
" highlight NonText guibg=#060606
" highlight Folded  guibg=#0A0A0A guifg=#9090D0

" Tab completion options
" (only complete to the longest unambiguous match, and show a menu)
highlight PmenuSel ctermfg=black
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
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

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
" OPEN FILES
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

map <Leader>vi :tabe ~/.vimrc<CR>
map <Leader>ee :tabe ~/.espanso.yml<CR>
map <Leader>zz :tabe ~/.zshrc<CR>

map <Leader>ab :tabe app/models/ability.rb<CR>
map <Leader>ev :tabe .env<CR>
map <Leader>gm :tabe Gemfile<CR>
map <Leader>rt :tabe config/routes.rb<CR>
map <Leader>sc :tabe config/schedule.rb<cr>
map <Leader>sk :tabe db/schema.rb<cr>

map <Leader>dn :tabe ~/Dropbox/Rails/rails-freelance-neocamino.txt<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NEOVIM IN VSCODE
" https://github.com/vscode-neovim/vscode-neovim#invoking-vscode-actions-from-neovim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Open definition aside (default binding)
nnoremap <C-w>gd <Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>

" Find in files for word under curso
nnoremap ? <Cmd>call VSCodeNotify('workbench.action.findInFiles', { 'query': expand('<cword>')})<CR>

map <Leader>lm <Cmd>call VSCodeNotify('extension.railsLatestMigration')<CR>
map <Leader>gt <Cmd>call VSCodeNotify('workbench.action.nextEditorInGroup')<CR>
map <Leader>gT <Cmd>call VSCodeNotify('workbench.action.previousEditorInGroup')<CR>
map <Leader>gr <Cmd>call VSCodeNotify('extension.ripgrep')<CR>
map gh <Cmd>call VSCodeNotify('gitlens.openCommitOnRemote')<CR>

" Comment visual blocks in VSCode
if exists('g:vscode')
  "map gc <Cmd>call VSCodeNotify('editor.action.commentLine')<CR>
  xnoremap <expr> gc <SID>vscodeCommentary()
  nnoremap <expr> gc <SID>vscodeCommentary() . '_'
  xmap gc <Plug>VSCodeCommentarygv
  nmap gc <Plug>VSCodeCommentaryLinegv
endif


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RSPEC MACROS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! RSpecCurrent()
  execute("!bin/rspec " . expand("%p") . ":" . line("."))
endfunction

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
