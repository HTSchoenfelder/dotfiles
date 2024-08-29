#! /bin/bash

sudo pacman -Syu --noconfirm
sudo pacman -Sy --needed --noconfirm \
    base-devel \
    bat \
    cifs-utils \
    curl \
    direnv \
    docker \
    dunst \
    fzf \
    git \
    gnupg \
    go \
    hey \
    htop \
    hyprpaper \
    jq \
    keepassxc \
    kubectl \
    man-db \
    neovim \
    obsidian \
    pass \
    pavucontrol \
    qpwgraph \
    ripgrep \
    ruby \
    starship \
    stow \
    tldr \
    tmux \
    ttf-agave-nerd \
    waybar \
    wireplumber \
    wl-clipboard \
    wtype \
    yazi \
    zoxide \
    zsh \
    zsh-autosuggestions \
    qemu-full \
    virt-manager \
    dnsmasq \
    bridge-utils \
    noto-fonts-emoji \
    udiskie \
    xdg-desktop-portal-hyprland \
    zellij \
    azure-cli \
    netcat \
    terraform
    

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
    zsh-fast-syntax-highlighting \
    spotify-launcher \
    synology-drive \
    neofetch \
    clipse \
    hyprpicker-git

if [ -d ~/dotfiles ]; then
    echo "dotfiles already cloned ..."
    git -C ~/dotfiles pull
else
    echo "Cloning dotfiles ..."
    git clone https://github.com/htschoenfelder/dotfiles.git
fi

mkdir -p ~/.local/bin

./scripts/setup-git.sh

mkdir -p ~/.docker/completions
docker completion zsh > ~/.docker/completions/_docker

rm ~/.gitconfig
rm ~/.zshrc
rm ~/.config/hypr/hyprland.conf

stow stow

bat cache --build

sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd

set-timezone Europe/Berlin

chsh -s $(which zsh)
