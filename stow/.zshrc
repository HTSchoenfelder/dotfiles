export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="henrik"

zstyle ':omz:update' mode reminder  # just remind me to update when it's time

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

# source $ZSH/oh-my-zsh.sh

alias cl='clear'
alias d='docker'
alias k='kubectl'
alias dotnet-install='curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin'
# use without arguments to install latest sdk and runtime
# dotnet-install --runtime dotnet --channel 7.0

alias dps='docker ps --format "table {{printf \"%.20s\" .Names}}\t{{.Image}}\t{{.Command}}\t{{.ID}}\t{{printf \"%.15s\" .Status}}"'

alias ll='ls -alF'
alias la='ls -A'
alias l='colorls -aog'
alias x='exec zsh'

alias code='code --profile Default --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland'
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

fpath=(~/.docker/completions $fpath)

source /usr/share/nvm/init-nvm.sh

# Load and initialize the Zsh completion library
autoload -Uz compinit
compinit

# zsh parameter completion for the dotnet CLI
_dotnet_zsh_complete()
{
  local completions=("$(dotnet complete "$words")")

  # If the completion list is empty, just continue with filename selection
  if [ -z "$completions" ]
  then
    _arguments '*::arguments: _normal'
    return
  fi

  # This is not a variable assignment, don't remove spaces!
  _values = "${(ps:\n:)completions}"
}
compdef _dotnet_zsh_complete dotnet

source <(fzf --zsh)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

source <(kubectl completion zsh)

eval "$(direnv hook zsh)"

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

bindkey "^[[3~" delete-char
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

if [[ -z "$ZELLIJ" && "$TERM" == "xterm-kitty" ]]; then
  zellij
fi

