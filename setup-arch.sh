#! /bin/bash

sudo pacman -Syu
sudo pacman -S --needed \
    base-devel\
    git \
    pass \
    gnupg \
    neovim \
    curl \
    jq \
    pavucontrol \
    qpwgraph \
    ripgrep \
    stow \
    hey \
    htop \
    tmux \
    cifs-utils \
    ruby \
    zoxide \
    bat \
    fzf \
    ttf-agave-nerd \
    starship

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
yay --version

yay -Syu
yay -S --needed \
    git-credential-manager \
    visual-studio-code-bin

if [ -d "~/dotfiles" ]; then
    echo "dotfiles already cloned ..."
    cd dotfiles
    git pull
else
    echo "Cloning dotfiles ..."
    git clone https://github.com/htschoenfelder/dotfiles.git
    cd dotfiles
fi

pwd

mkdir -p ~/.local/bin

./scripts/setup-git.sh

rm ~/.gitconfig
rm ~/.zshrc
stow stow

sudo chsh -s $(which zsh)