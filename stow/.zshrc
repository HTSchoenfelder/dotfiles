export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="henrik"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# https://gist.github.com/n1snt/454b879b8f0b7995740ae04c5fb5b7df

plugins=( \
          git \
          docker \
          docker-compose \
          dotnet \
          dotenv \
          kubectl \
          zsh-autosuggestions \
          # zsh-autocomplete \
          zsh-syntax-highlighting \
          fast-syntax-highlighting\
          )

source $ZSH/oh-my-zsh.sh
# eval "$(oh-my-posh init zsh --config ~/dotfiles/misc/omp.json)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

alias cl='clear'
alias d='docker'
alias k='kubectl'
alias dotnet-install='curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin'

alias dps='docker ps --format "table {{printf \"%.20s\" .Names}}\t{{.Image}}\t{{.Command}}\t{{.ID}}\t{{printf \"%.15s\" .Status}}"'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias code='code --profile Default'
alias proj='cd ~/projects'

alias aza='az account show --output tsv --query "name"'
alias azas='az account set --subscription'

mc() {
    mkdir -p $@ && cd ${@:$#}
}

function lu() {
    echo -e "User-ID Username"
    echo "---------------------------"
    getent passwd | awk -F':' '{ printf "%-8s %s\n", $3, $1 }' | sort -n -k 1
}

function lg() {
    echo -e "Group-ID Groupname"
    echo "---------------------------"
    getent group | awk -F':' '{ printf "%-8s %s\n", $3, $1 }' | sort -n -k 1
}

export PATH=~/.dotnet:$PATH
export PATH=~/.dotnet/tools:$PATH
export PATH=~/.local/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export DOTNET_ROOT=/home/henrik/.dotnet

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
