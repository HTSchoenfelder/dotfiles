#! /bin/bash

sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update && sudo apt install -y git stow

pwd

mkdir -p ~/.local/bin

./setup-gnome-shell-extensions.sh
./setup-shell.sh
./install-packages.sh
./setup-git.sh

rm ~/.gitconfig
rm ~/.zshrc

cd ~/dotfiles
stow home --no-folding
sudo chsh -s $(which zsh)