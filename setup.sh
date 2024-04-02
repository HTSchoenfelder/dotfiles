#! /bin/bash

if [ -d "~/dotfiles" ]; then
    echo "dotfiles already cloned ..."    
else
    echo "Cloning dotfiles ..."

    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt update && sudo apt install -y git

    git clone https://github.com/htschoenfelder/dotfiles.git
    cd dotfiles
fi

pwd

./scripts/install.sh
./scripts/setup-git.sh
./scripts/setup-shell-extensions.sh

sudo usermod -aG docker $USER

rm ~/.gitconfig
rm ~/.zshrc
stow stow

chsh -s $(which zsh)
exec zsh
