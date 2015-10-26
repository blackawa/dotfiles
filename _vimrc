"行数を表示
set number
"シンタックスハイライトを有効にする
syntax on
set shiftwidth=2

"キーボードショートカット
"NERDTreeをCtrl+Eで開く 
nnoremap <silent><C-e> :NERDTreeToggle<CR>

"Neobundle
filetype off
filetype plugin indent off
if has('vim_starting')
    if &compatible
        set compatible
    endif

    set rtp+=~/dotfiles/neobundle.vim/
endif

"Required
call neobundle#begin(expand('~/dotfiles/'))
NeoBundleFetch 'Shougo/neobundle.vim'
"Managed Plug-in
NeoBundle 'Shougo/neocomplete.vim'                  "候補のボッブアッブ表示
NeoBundle 'Shougo/unite.vim.git'                    "ファイルオープンを便利に
NeoBundle 'scrooloose/nerdtree'                     "カレントディレクトリのツリーを表示
NeoBundle 'tpope/vim-endwise'                       "Rubyの簡単なコード補完
NeoBundle 'nathanaelkane/vim-indent-guides'         "インデントを表示
NeoBundle 'vim-scripts/AnsiEsc.vim'                 "ANSIカラー情報があるファイルの色を表示する
NeoBundle 'tomasr/molokai'			    "カラースキーマMolokai
NeoBundle 'Yggdroot/indentLine'                     "インデントを視覚化する
NeoBundle 'jiangmiao/simple-javascript-indenter'    "JavaScriptのインデントを整形
NeoBundle 'jelera/vim-javascript-syntax'            "JavaScriptのシンタックス設定
NeoBundle 'mattn/emmet-vim'                         "emmetを導入する
"NeoBundle 'scrooloose/syntastic'                    "コードのシンタックスチェックを行う
"end of NeoBundle
call neobundle#end()

filetype plugin indent on

autocmd BufNewFile,BufReadPost *.md set filetype=markdown

NeoBundleCheck

"syntasticの設定
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
