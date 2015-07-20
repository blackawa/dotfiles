"行数を表示
set number
"シンタックスハイライトを有効にする
syntax on

"Neobundle
filetype off
if has('vim_starting')
    if &compatible
        set compatible
    endif

    set rtp+=./neobundle.vim/
endif
"Required
call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'
"Managed Plug-ins
NeoBundle 'Shougo/neocomplcache.git'
NeoBundle 'Shougo/unite.vim.git'
"end of NeoBundle
call neobundle#end()
filetype plugin indent on

NeoBundleCheck
