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

alias cl='clear'
alias d='docker'
alias k='kubectl'
alias dotnet-install='curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias code='code --profile Default'
alias proj='cd ~/projects'

mc() {
    mkdir -p $@ && cd ${@:$#}
}

export PATH=~/.dotnet:$PATH
export PATH=~/.dotnet/tools:$PATH
export PATH=~/.local/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export DOTNET_ROOT=/home/henrik/.dotnet

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
