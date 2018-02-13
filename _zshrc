## --- zgen configurationsj
# load zgen
source "${HOME}/.zgen/zgen.zsh"

# if the init scipt doesn't exist
if ! zgen saved; then
  echo "Creating a zgen save"
  # specify plugins here
  zgen oh-my-zsh

  # plugins
  zgen oh-my-zsh plugins/git
  zgen oh-my-zsh plugins/sudo
  zgen oh-my-zsh plugins/command-not-found
  zgen load zsh-users/zsh-syntax-highlighting
  zgen load /path/to/super-secret-private-plugin
  # bulk load
  zgen loadall <<EOPLUGINS
  zsh-users/zsh-history-substring-search
  /path/to/local/plugin
EOPLUGINS

  # completion
  zgen load zsh-users/zsh-completions src

  # theme
  zgen oh-my-zsh themes/robbyrussell

  # generate the init script from plugins above
  zgen save
fi
## --- zgen configurations

# User configuration
# aliases
alias v=vim
alias e='emacs -nw'
alias dk=docker
alias dkcp=docker-compose
alias dke='(){ docker exec -it $1 /bin/bash }'
alias dki='docker images'
alias kc='kubectl'

# rbenv
eval "$(rbenv init -)"
# golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export GO15VENDOREXPERIMENT=1

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# kube-ps1
source ~/.kube-ps1/kube-ps1.sh
PROMPT='$(kube_ps1)'$PROMPT
## Default off
kubeoff

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

export PHPENV_ROOT="$HOME/.phpenv"
if [ -d "${PHPENV_ROOT}" ]; then
  export PATH="${PHPENV_ROOT}/bin:${PATH}"
  eval "$(phpenv init -)"
fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/blackawa/Downloads/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/blackawa/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/blackawa/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/blackawa/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
