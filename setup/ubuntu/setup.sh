#! /bin/sh

sudo apt update && sudo apt install -y \
    stow \
    jq \
    bat \
    zsh \
    fzf \
    direnv \
    zoxide \
    wget \
    apt-transport-https

# starship
curl -sS https://starship.rs/install.sh | sh

# zsh-autosuggestions & fast-syntax-highlighting
ZSH_CUSTOM_DEFAULT=/usr/share/zsh
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/fast-syntax-highlighting

# vscode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' && rm -f packages.microsoft.gpg

#kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# terraform
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# stackit-cli
curl https://packages.stackit.cloud/keys/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/stackit.gpg
echo "deb [signed-by=/usr/share/keyrings/stackit.gpg] https://packages.stackit.cloud/apt/cli stackit main" | sudo tee -a /etc/apt/sources.list.d/stackit.list

sudo apt update && sudo apt install -y \
  code \
  terraform \
  stackit