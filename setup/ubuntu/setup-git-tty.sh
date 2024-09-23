#! /bin/sh

apt update
apt install -y \
      software-properties-common \
      curl \
      pass \
      gnupg \
      jq

add-apt-repository -y ppa:git-core/ppa
apt update
apt install -y git

# Install Git Credential Manager
releases_url="https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest"
deb_download_url=$(curl -s "$releases_url" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
curl -L -o ./git-credential-manager.deb "$deb_download_url"
apt install -y ./git-credential-manager.deb
rm ./git-credential-manager.deb

KEY_ID="Henrik Schönfelder <mail@henrikschoenfelder.de>"
gpg --quick-generate-key "$KEY_ID" default default 2y
pass init $KEY_ID

git-credential-manager configure
git config --global credential.credentialStore gpg

export GPG_TTY=$(tty)