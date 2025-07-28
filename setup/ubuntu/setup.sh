#! /bin/sh

sudo apt update && sudo apt install -y \
    stow \
    jq \
    bat \
    zsh \
    fzf \
    direnv \
    zoxide

curl -sS https://starship.rs/install.sh | sh

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

ZSH_CUSTOM_DEFAULT=/usr/share/zsh
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/fast-syntax-highlighting

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash