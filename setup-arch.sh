#! /bin/bash

sudo pacman -Syu --noconfirm

sudo pacman -Sy --needed --noconfirm \
    git \
    docker \
    go \
    terraform \
    kubectl \
    base-devel \
    ruby \
    helm \
    lazygit \
    azure-cli \
    starship \
    direnv \
    zsh \
    neovim \
    vim \
    zsh-autosuggestions \
    fzf \
    curl \
    bat \
    ripgrep \
    jq \
    tldr \
    tmux \
    zellij \
    zoxide \
    htop \
    nano \
    stow \
    gnupg \
    pass \
    keepassxc \
    neofetch \
    obsidian \
    spotify-launcher \
    nautilus \
    openssh \
    wget \
    grim \
    slurp \
    udiskie \
    netcat \
    smartmontools \
    iwd \
    wpa_supplicant \
    dnsmasq \
    bridge-utils \
    wireless_tools \
    cifs-utils \
    man-db \
    polkit-kde-agent \
    ly \
    hyprland \
    waybar \
    dunst \
    kitty \
    hyprpaper \
    wl-clipboard \
    yazi \
    wtype \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-utils \
    qt5-wayland \
    qt6-wayland \
    noto-fonts-emoji \
    ttf-agave-nerd \
    wireplumber \
    pavucontrol \
    qpwgraph \
    qemu-full \
    virt-manager \
    desktop-file-utils \
    font-manager \
    firefox

    
## check if yay is installed by calling yay --version and only then install it
if yay --version &> /dev/null; then
    echo "yay already installed ..."
else
    echo "Installing yay ..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    yes | makepkg -si
    cd
fi
yay --version

yay -Syu
yes | LANG=C yay -Sy --needed --noconfirm --answerdiff None --answerclean None --mflags "--noconfirm" \
    visual-studio-code-bin \
    ruby-colorls \
    google-chrome \
    nvm \
    tofi \
    zsh-fast-syntax-highlighting \
    synology-drive \
    clipse \
    hyprpicker \
    firefox-pwa-bin \
    nvm \
    wlogout


mkdir -p ~/.local/bin

mkdir -p ~/.docker/completions
docker completion zsh > ~/.docker/completions/_docker

rm ~/.gitconfig
rm ~/.zshrc
rm ~/.config/hypr/hyprland.conf

stow stow --no-folding

bat cache --build

# Virtualization
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd

# Docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker

sudo systemctl enable --now ly

set-timezone Europe/Berlin

mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work

firefox --createprofile "defaultprofile $HOME/.mozilla/firefox/defaultprofile"

chsh -s $(which zsh)

echo "Execute stow stow"
