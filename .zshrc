setopt HIST_IGNORE_DUPS
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt autocd beep extendedglob
bindkey -e
zstyle :compinstall filename '/home/blackawa/.zshrc'
# 補完時に大文字小文字を適度に無視する
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

autoload -Uz compinit promptinit
compinit
promptinit
prompt walters

# 標準出力が消えないようにする
setopt prompt_cr
setopt prompt_sp

# RPROMPTの消し方がわからなかったから空文字で上書きする
RPROMPT=""

autoload -Uz vcs_info
precmd() {
    vcs_info
    if [[ -n ${vcs_info_msg_0_} ]]; then
        # vcs_info found something, that needs space.
        PS1="%3~${vcs_info_msg_0_}%$ # "
    else
        # Nothing from vcs_info, so we got more space.
        PS1="%5~%$ $ "
    fi
}

alias e='emacs -nw'
alias g='git'
alias kc='kubectl'
alias dk='docker'
alias dkcp='docker-compose'
alias 256colors='for c in {000..255}; do echo -n "\e[38;5;${c}m $c" ; [ $(($c%16)) -eq 15 ] && echo;done;echo'

# external sources
source ~/git/github.com/rupa/z/z.sh
source /usr/local/bin/google-cloud-sdk/completion.zsh.inc

# update path
typeset -U path
path=(/usr/local/bin/google-cloud-sdk/bin $path[@])

export SDKMAN_DIR="$HOME/.sdkman"
export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# rbenv
path=(~/.rbenv/bin $path[@])
eval "$(rbenv init -)"

# nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# This must be at end of .zshrc!
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


