"行数を表示
set number
"シンタックスハイライトを有効にする
syntax on
"インデント設定
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
"保存時に行末スペースを削除する
autocmd BufWritePre * :%s/\s\+$//ge

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
"=== Managed Plug-in ===
"候補のボッブアッブ表示
NeoBundle 'Shougo/neocomplete.vim'
"ファイルオープンを便利に
NeoBundle 'Shougo/unite.vim.git'
"カレントディレクトリのツリーを表示
NeoBundle 'scrooloose/nerdtree'
"Rubyの簡単なコード補完
NeoBundle 'tpope/vim-endwise'
"インデントを表示
NeoBundle 'nathanaelkane/vim-indent-guides'
"ANSIカラー情報があるファイルの色を表示する
NeoBundle 'vim-scripts/AnsiEsc.vim'
"カラースキーマMolokai
NeoBundle 'tomasr/molokai'
"インデントを視覚化する
NeoBundle 'Yggdroot/indentLine'
"JavaScriptのインデントを整形
NeoBundle 'jiangmiao/simple-javascript-indenter'
"JavaScriptのシンタックス設定
NeoBundle 'jelera/vim-javascript-syntax'
"emmetを導入する
NeoBundle 'mattn/emmet-vim'
"コードのシンタックスチェックを行う
"NeoBundle 'scrooloose/syntastic'
""Typescriptのシンタックスハイライト
NeoBundle 'leafgarland/typescript-vim'
"Coffescriptのシンタックスハイライト
NeoBundle 'kchmck/vim-coffee-script'
" golangのシンタックスハイライト
NeoBundle 'fatih/vim-go'
" ネストしたカッコの色を変える
NeoBundle 'kien/rainbow_parentheses.vim'
" ClojureのコードをREPLで評価する
NeoBundle "tpope/vim-fireplace"
" classpathをロードしてくれる
NeoBundle "tpope/vim-classpath"
" emoji in vim
NeoBundle "junegunn/vim-emoji"
"=== end of NeoBundle ===
call neobundle#end()

filetype plugin indent on

autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" kien/rainbow_parentheses.vim の設定を有効化
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

" emoji in vimの自動補完設定追加
set completefunc=emoji#complete

NeoBundleCheck

"syntasticの設定
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
