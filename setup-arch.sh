#! /bin/bash

sudo pacman -Syu --noconfirm
sudo pacman -Sy --needed --noconfirm - < ~/dotfiles/pacman.txt

## check if yay is installed by calling yay --version and only then install it
if yay --version &> /dev/null; then
    echo "yay already installed ..."
else
    echo "Installing yay ..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    yes | makepkg -si
    cd
fi
yay --version

yay -Syu
yes | LANG=C yay -Sy --needed --noconfirm --answerdiff None --answerclean None --mflags "--noconfirm" \
    git-credential-manager \
    visual-studio-code-bin \
    ruby-colorls \
    google-chrome \
    nvm \
    tofi \
    zsh-fast-syntax-highlighting

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

wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme

mkdir -p ~/.docker/completions
docker completion zsh > ~/.docker/completions/_docker

rm ~/.gitconfig
rm ~/.zshrc
rm ~/.config/hypr/hypr.conf

stow stow

bat cache --build

chsh -s $(which zsh)
