#! /bin/bash

KEY_ID="Henrik Schönfelder <mail@henrikschoenfelder.de>"

if ! gpg --list-keys | grep -q "$KEY_ID"; then
    echo "Key $KEY_ID does not exist. Executing actions."
    gpg --generate-key
    pass init "Henrik Schönfelder <mail@henrikschoenfelder.de>"
else
    echo "Key $KEY_ID already exists."
fi

git-credential-manager configure


mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work

cp ~/dotfiles/misc/.gitconfig_template ~/projects/work/.gitconfig_work
cp ~/dotfiles/misc/.gitconfig_template ~/.gitconfig_machine