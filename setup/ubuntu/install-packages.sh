#! /usr/bin/env bash

sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
      git \
      software-properties-common \
      apt-transport-https \
      make \
      build-essential \
      libfuse2 \
      curl \
      pass \
      gnupg \
      jq \
      pavucontrol \
      qpwgraph \
      ca-certificates \
      zsh \
      ripgrep \
      stow \
      hey \
      htop \
      tmux \
      xdotool \
      cifs-utils \
      ruby-full \
      konsole \
      zoxide \
      bat

mkdir -p ~/software
mkdir -p ~/.local/bin

# Install Git Credential Manager
releases_url="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ./git-credential-manager.deb "$deb_download_url"
sudo apt install ./git-credential-manager.deb
rm ./git-credential-manager.deb

# Virtualization
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cpu-checker qemu-utils
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd

# Chrome
curl -o ~/Downloads/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ~/Downloads/google-chrome-stable_current_amd64.deb

# VS Code
curl -L -o ~/Downloads/vscode.deb http://go.microsoft.com/fwlink/?LinkID=760868
sudo apt install ~/Downloads/vscode.deb

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client

# KeePassXC
add-apt-repository -y ppa:phoerious/keepassxc
sudo apt update
sudo apt install -y keepassxc

# workrave
add-apt-repository -y ppa:rob-caelers/workrave
sudo apt update
sudo apt install -y workrave-gnome

#Obsidian
releases_url="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ~/Downloads/obsidian.deb "$deb_download_url"
sudo apt install ~/Downloads/obsidian.deb

# Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# Docker Dive
DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -OL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb
sudo apt install ./dive_${DIVE_VERSION}_linux_amd64.deb

# PowerShell
source /etc/os-release
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# neovim
curl -L -o ~/software/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x ~/software/nvim.appimage
ln -s ~/software/nvim.appimage ~/.local/bin/nvim

# Go
LATEST_GO_VERSION="$(curl --silent 'https://go.dev/VERSION?m=text' | head -n 1)"
LATEST_GO_DOWNLOAD_URL="https://go.dev/dl/${LATEST_GO_VERSION}.linux-amd64.tar.gz"
curl -L -o ~/Downloads/go.tar.gz "$LATEST_GO_DOWNLOAD_URL"
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf ~/Downloads/go.tar.gz

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly -y
sudo apt install -y \
     cmake \
     pkg-config \
     libfreetype6-dev \
     libfontconfig1-dev \
     libxcb-xfixes0-dev \
     libxkbcommon-dev \
     python3


# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | sudo bash

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Azure Data Studio
curl -L -o ~/Downloads/azureDataStudio.deb https://go.microsoft.com/fwlink/?linkid=2251736
sudo apt install ~/Downloads/azureDataStudio.deb

# Oh My Posh
curl -s https://ohmyposh.dev/install.sh | sudo bash -s

# Synology Drive
curl -o ~/Downloads/synology-drive-client.deb https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.4.0-15724/Ubuntu/Installer/synology-drive-client-15724.x86_64.deb
sudo apt install ~/Downloads/synology-drive-client.deb
