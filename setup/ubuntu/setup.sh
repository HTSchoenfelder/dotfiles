#! /bin/sh

sudo apt update && sudo apt install -y \
    stow \
    jq \
    bat \
    zsh 

curl -sS https://starship.rs/install.sh | sh