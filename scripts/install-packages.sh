#! /bin/bash

apt update && apt upgrade -y
apt install -y \
      software-properties-common \
      make \
      build-essential \
      libfuse2 \
      curl \
      pass \
      gnupg \
      jq \
      pavucontrol \
      ca-certificates \
      zsh \
      guake \
      ripgrep \
      stow \
      hey \
      htop \
      tmux

mkdir -p ~/software
mkdir -p ~/.local/bin

# Chrome
curl -o ~/Downloads/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ~/Downloads/google-chrome-stable_current_amd64.deb

# VS Code
curl -L -o ~/Downloads/vscode.deb http://go.microsoft.com/fwlink/?LinkID=760868
apt install ~/Downloads/vscode.deb

# Spotify
curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list
apt-get update && apt-get install spotify-client

# KeePassXC
add-apt-repository -y ppa:phoerious/keepassxc
apt update
apt install -y keepassxc

# workrave
add-apt-repository -y ppa:rob-caelers/workrave
apt update
apt install -y workrave-gnome

#Obsidian
releases_url="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ~/Downloads/obsidian.deb "$deb_download_url"
apt install ~/Downloads/obsidian.deb

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker $USER

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# neovim
curl -L -o ~/software/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x ~/software/nvim.appimage
ln -s ~/software/nvim.appimage ~/.local/bin/nvim

# Go
LATEST_GO_VERSION="$(curl --silent 'https://go.dev/VERSION?m=text' | head -n 1)"
LATEST_GO_DOWNLOAD_URL="https://go.dev/dl/${LATEST_GO_VERSION}.linux-amd64.tar.gz"
curl -L -o ~/Downloads/go.tar.gz "$LATEST_GO_DOWNLOAD_URL"
rm -rf /usr/local/go && tar -C /usr/local -xzf ~/Downloads/go.tar.gz

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | bash

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Azure Data Studio
curl -L -o ~/Downloads/azureDataStudio.deb https://go.microsoft.com/fwlink/?linkid=2251736
apt install ~/Downloads/azureDataStudio.deb

# PowerShell
curl -L -o ~/Downloads/powershell.deb https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell-lts_7.4.1-1.deb_amd64.deb
apt install ~/Downloads/powershell.deb

# Synology Drive
curl -o ~/Downloads/synology-drive-client.deb https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.4.0-15724/Ubuntu/Installer/synology-drive-client-15724.x86_64.deb
apt install ~/Downloads/synology-drive-client.deb