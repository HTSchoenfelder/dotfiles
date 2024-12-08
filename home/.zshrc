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
alias lsdev='lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT'
alias cd="z"
alias cdc="cd"
alias c="wl-copy"
alias tfarm="export ARM_SUBSCRIPTION_ID=$(az account show | jq -r .id)"

alias code='code --profile Default --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland'
alias proj='cd ~/projects'

alias aza='az account show --output tsv --query "name"'
alias azas='az account set --subscription'

alias nixbuild='sudo nixos-rebuild switch --flake $HOME/dotfiles/setup/nixos'
alias nixbuildv='sudo nixos-rebuild switch --flake $HOME/dotfiles/setup/nixos --show-trace --print-build-logs --verbose'
alias nixupdate='nix flake update --flake $HOME/dotfiles/setup/nixos'
alias nixrepl='nix repl -f flake:nixpkgs'

alias nclisten='echo "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\nHello World" | nc -l -N 8080'
alias pythonweb='python3 -m http.server 8080'
alias ncsw='nc towel.blinkenlights.nl 23'

alias gitlc='export LATEST_COMMIT=$(git rev-parse HEAD)'

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
export PATH=$PATH:/home/henrik/.dapr/bin

# export DOTNET_ROOT=/home/henrik/.dotnet

fpath=(~/.docker/completions $fpath)

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

if ! nix-env --version &> /dev/null; then
  source /usr/share/nvm/init-nvm.sh
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fi

source <(kubectl completion zsh)

eval "$(direnv hook zsh)"

eval "$(zoxide init zsh)"

eval "$(starship init zsh)"

bindkey "^[[3~" delete-char
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

if [[ "$TERM" == "xterm-kitty" ]]; then
  eval "$(zellij setup --generate-auto-start zsh)"
fi
