" Minimum config
execute pathogen#infect()
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
" Navigation
map <Leader>sm :RSmodel
map <Leader>sv :RSview 
map <Leader>sc :RScontroller
map <Leader>vm :RVmodel<cr>
map <Leader>vv :RVview<cr>
map <Leader>vc :RVcontroller<cr>
map <Leader>ra :%s/
map <Leader>sc :tabe db/schema.rb<cr>
map <Leader>fa :tabe spec/factories.rb<CR>
map <Leader>rt :tabe config/routes.rb<CR>
" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path
map <Leader>e :e <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>s :split <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>v :vnew <C-R>=expand("%:p:h") . '/'<CR>
map <Leader>t :tabe <C-R>=expand("%:p:h") . '/'<CR>
" Tests
map <Leader>td :!bundle exec rspec % --format documentation<CR>
map <Leader>tr :!bundle exec rspec spec<CR>
map <Leader>tt :!bundle exec rspec fast_spec<CR>
map <Leader>tm :!bundle exec rspec spec/models<CR>
map <Leader>tc :!bundle exec rspec spec/controllers<CR>
map <Leader>tf :!bundle exec rspec spec/features<CR>
map <Leader>sj :call OpenJasmineSpecInBrowser()<cr>
" Git
map <Leader>gd :!git diff<CR>
map <Leader>gs :!git status<CR>
" Search and replace
map <Leader>rw :%s/\s\+$//<cr>:w<cr>
map <Leader>vg :vsp<cr>:grep 
" Maps auto-complete to tab
imap <Tab> <C-N>
imap <C-L> <Space>=><Space>
" Other
map <Leader>co ggVG"*y
map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>

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
set autoindent
set formatoptions-=or " Don't add the comment prefix when I hit enter or o/O on a comment line.

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
