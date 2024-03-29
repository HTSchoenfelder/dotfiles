#! /bin/bash

if [ -d "~/dotfiles" ]; then
    echo "Cloning dotfiles..."

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update
    sudo apt install -y git

    sudo apt update && sudo apt install git -y
    git clone https://github.com/htschoenfelder/dotfiles.git
    cd dotfiles
else
    echo "dotfiles already cloned. Skipping..."
fi

pwd

./scripts/install.sh
./scripts/setup-git.sh
./scripts/setup-shell-extensions.sh

chsh -s $(which zsh)
sudo usermod -aG docker $USER

rm rm ~/.gitconfig
rm rm ~/.zshrc
stow stow
exec zsh
