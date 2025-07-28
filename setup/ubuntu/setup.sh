#! /bin/sh

sudo apt update && sudo apt install -y \
    stow \
    jq \
    bat \
    zsh \
    fzf \
    kubectl \
    direnv \
    zoxide

curl -sS https://starship.rs/install.sh | sh