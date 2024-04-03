#! /bin/bash

add-apt-repository -y ppa:git-core/ppa
apt update && apt install -y git stow

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
rm ~/.gitconfig
rm ~/.zshrc
stow stow

./scripts/setup-git.sh
./scripts/setup-shell.sh
./scripts/setup-gnome-shell-extensions.sh
./scripts/install-packages.sh

exec zsh
chsh -s $(which zsh)