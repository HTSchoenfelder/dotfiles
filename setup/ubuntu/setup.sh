#! /bin/sh

sudo apt update && sudo apt install -y \
    stow \
    jq \
    bat \
    zsh \
    fzf \
    direnv \
    zoxide \
    wget

curl -sS https://starship.rs/install.sh | sh

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

ZSH_CUSTOM_DEFAULT=/usr/share/zsh
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/fast-syntax-highlighting

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && rm -f packages.microsoft.gpg && sudo apt-get install apt-transport-https && sudo apt-get update && sudo apt-get install -y code