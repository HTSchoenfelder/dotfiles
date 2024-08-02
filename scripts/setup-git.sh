#! /bin/bash

KEY_ID="Henrik Schönfelder <mail@henrikschoenfelder.de>"

if ! gpg --list-keys | grep -q "$KEY_ID"; then
    echo "Key $KEY_ID does not exist. Executing actions."
    export GPG_TTY=$(tty)
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

cp ~/dotfiles/misc/.gitconfig_template ~/.gitconfig_machine