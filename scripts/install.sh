#! /bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
      curl \
      jq \
      dconf-editor \
      pavucontrol \
      software-properties-common \
      pass \
      gnome-browser-connector \
      gnome-shell-extensions \
      gnome-tweaks \
      ca-certificates \
      gnupg \
      zsh \
      guake \
      libfuse2 \
      ripgrep \
      stow \
      hey \
      htop

mkdir -p ~/software
mkdir -p ~/.local/bin

# Git
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt install -y git

# Git Credential Manager
releases_url="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ~/Downloads/git-credential-manager.deb "$deb_download_url"
sudo apt install ~/Downloads/git-credential-manager.deb

# Chrome
curl -o ~/Downloads/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ~/Downloads/google-chrome-stable_current_amd64.deb

# VS Code
curl -L -o ~/Downloads/vscode.deb http://go.microsoft.com/fwlink/?LinkID=760868
sudo apt install ~/Downloads/vscode.deb

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt install -y spotify-client

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

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Data Studio
curl -L -o ~/Downloads/azureDataStudio.deb https://go.microsoft.com/fwlink/?linkid=2251736
sudo apt install ~/Downloads/azureDataStudio.deb

# ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Nerd Font
font_name="Agave"
curl -OL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"
mkdir -p  "$HOME/.fonts"
unzip -o "$font_name.zip" -d "$HOME/.fonts/$font_name/"
fc-cache -fv

# PowerShell
curl -L -o ~/Downloads/powershell.deb https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell-lts_7.4.1-1.deb_amd64.deb
sudo apt install ~/Downloads/powershell.deb

# Synology Drive
curl -o ~/Downloads/synology-drive-client.deb https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.4.0-15724/Ubuntu/Installer/synology-drive-client-15724.x86_64.deb
sudo apt install ~/Downloads/synology-drive-client.deb