#! /usr/bin/env bash

echo "Saving VSCode extensions..."
code --list-extensions > "$HOME"/dotfiles/misc/code_extensions.txt