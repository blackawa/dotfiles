"行数を表示
set number
"シンタックスハイライトを有効にする
syntax on
set shiftwidth=4

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
NeoBundle 'Shougo/neocomplete.vim'                 "候補のボッブアッブ表示
NeoBundle 'Shougo/unite.vim.git'                   "ファイルオープンを便利に
NeoBundle 'scrooloose/nerdtree'                    "カレントディレクトリのツリーを表示
NeoBundle 'tpope/vim-endwise'                      "Rubyの簡単なコード補完
NeoBundle 'nathanaelkane/vim-indent-guides'        "インデントを表示
NeoBundle 'vim-scripts/AnsiEsc.vim'                "ANSIカラー情報があるファイルの色を表示する
NeoBundle 'tomasr/molokai'			   "カラースキーマMolokai
NeoBundle 'Yggdroot/indentLine'                    "インデントを視覚化する
NeoBundle 'jiangmiao/simple-javascript-indenter'   "JavaScriptのインデントを整形
NeoBundle 'jelera/vim-javascript-syntax'           "JavaScriptのシンタックス設定
"end of NeoBundle
call neobundle#end()
filetype plugin indent on

NeoBundleCheck
