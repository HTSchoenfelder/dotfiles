source $HOME/.zshrc_core
source $HOME/.zshrc_notify

alias d='docker'
alias dps='docker ps --format "table {{printf \"%.20s\" .Names}}\t{{.Image}}\t{{.Command}}\t{{.ID}}\t{{printf \"%.15s\" .Status}}"'
alias dv='curl --unix-socket /var/run/docker.sock http://localhost/version | jq'
alias k='kubectl'
alias kns='kubectl config set-context --current --namespace='
alias dotnet-install='curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin'
# use without arguments to install latest sdk and runtime
# dotnet-install --runtime dotnet --channel 7.0
alias ls='eza --icons --group-directories-first'
alias ll='eza -algF --icons --group-directories-first'
alias l='eza -alF --no-user --icons --group-directories-first'

alias x='exec zsh'
alias lsdev='lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT'
alias cd="z"
alias cdc="cd"
alias c="wl-copy"
alias myip="curl -s ifconfig.io | tee >(wl-copy)"

alias code='code --profile Default --enable-features=WebRTCPipeWireCapturer --ozone-platform-hint=wayland'
alias proj='cd ~/projects'

alias aza='az account show --output tsv --query "name"'
alias azas='az account set --subscription'

alias nixbuildv='sudo nixos-rebuild switch --flake $HOME/dotfiles/setup/nixos --show-trace --print-build-logs --verbose'
# alias nixupdate='nix flake update --flake $HOME/dotfiles/setup/nixos'
alias nixupdate='sudo nix flake update --flake ~/dotfiles/setup/macos/'
alias nixupdatelatest='nix flake update nixpkgs-latest --flake $HOME/dotfiles/setup/nixos'
alias nixupdatestable='nix flake update nixpkgs-stable --flake $HOME/dotfiles/setup/nixos'
alias nixrepl='nix repl -f flake:nixpkgs'

nixsh() {
    export NIXPKGS_ALLOW_UNFREE=1
    nix shell $(printf "nixpkgs#%s " "$@")
}

nixbuild() {
    if [ -z "$1" ]; then
        echo "Error: No target specified. Usage: nixbuild <target> [-v]" >&2
        return 1
    fi

    local flags=()
    if [ "$2" = "-v" ]; then
        flags=(--show-trace --print-build-logs --verbose)
    fi

    sudo nixos-rebuild switch --flake "$HOME/dotfiles/setup/nixos#$1" "${flags[@]}"
}

alias sshcp='echo "source <(wget -qO- gagelpuh.de/sh)" | wl-copy'
alias gitlc='export LATEST_COMMIT=$(git rev-parse HEAD)'
alias hyprevents='socat - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock'

tfarm() {
  export ARM_SUBSCRIPTION_ID=$(az account show | jq -r .id)
  echo "ARM_SUBSCRIPTION_ID set to: $ARM_SUBSCRIPTION_ID"
}

export PATH=~/.dotnet:$PATH
export PATH=~/.dotnet/tools:$PATH
export PATH=~/.local/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/home/henrik/.dapr/bin
# export DOTNET_ROOT=/home/henrik/.dotnet
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

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

export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"

source <(fzf --zsh)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

if ! nix --version &> /dev/null; then
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

if [[ "$START_ZELLIJ" == 1 ]]; then
  eval "$(zellij setup --generate-auto-start zsh)"
fi
