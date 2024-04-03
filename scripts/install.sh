#! /bin/bash

sudo apt update && sudo apt upgrade -y

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
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
      htop \
      tmux \
      make \
      build-essential \
      ttf-mscorefonts-installer

mkdir -p ~/software
mkdir -p ~/.local/bin

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

# Azure Developer CLI
curl -fsSL https://aka.ms/install-azd.sh | sudo bash

# nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Azure Data Studio
curl -L -o ~/Downloads/azureDataStudio.deb https://go.microsoft.com/fwlink/?linkid=2251736
sudo apt install ~/Downloads/azureDataStudio.deb

# ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM_DEFAULT=~/.oh-my-zsh/custom
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/fast-syntax-highlighting
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autocomplete


# Nerd Font
font_name="Agave"
curl -L -o ~/Downloads/$font_name.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"
mkdir -p  "$HOME/.fonts"
unzip -o "~/Downloads/$font_name.zip" -d "$HOME/.fonts/$font_name/"
fc-cache -fv

# PowerShell
curl -L -o ~/Downloads/powershell.deb https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/powershell-lts_7.4.1-1.deb_amd64.deb
sudo apt install ~/Downloads/powershell.deb

# Synology Drive
curl -o ~/Downloads/synology-drive-client.deb https://global.synologydownload.com/download/Utility/SynologyDriveClient/3.4.0-15724/Ubuntu/Installer/synology-drive-client-15724.x86_64.deb
sudo apt install ~/Downloads/synology-drive-client.deb