#! /bin/bash

# Install Packages
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt install -y \
      git \
      curl \
      pass \
      gnupg \
      jq

# Install Git Credential Manager
releases_url="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ./git-credential-manager.deb "$deb_download_url"
sudo apt install ./git-credential-manager.deb
rm ./git-credential-manager.deb

KEY_ID="Henrik Schönfelder <mail@henrikschoenfelder.de>"

if ! gpg --list-keys | grep -q "$KEY_ID"; then
    echo "Key $KEY_ID does not exist. Executing actions."
    gpg --quick-generate-key "$KEY_ID" default default 2y
else
    echo "Key $KEY_ID already exists."
fi

pass init $KEY_ID

git-credential-manager configure
git config --global credential.credentialStore gpg
# This adds the following to the ~/.gitconfig file:
# [credential]
# 	helper = 
# 	helper = /usr/local/bin/git-credential-manager
# 	credentialStore = gpg


mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work

cp ~/dotfiles/misc/.gitconfig_template ~/projects/work/.gitconfig_work
cp ~/dotfiles/misc/.gitconfig_template ~/.gitconfig_machine