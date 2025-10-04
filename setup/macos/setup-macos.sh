#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
  configuration=$1
else
  read -p "Enter the configuration: " configuration
fi

### Check if nix is available
if ! command -v nix &>/dev/null; then
    echo "Nix is not available."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

### Check if nix is available
if ! command -v brew &>/dev/null; then
    echo "Homebrew is not available."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

### Check if git is available
if ! command -v git &>/dev/null; then
    echo "Git is not available."
    echo "Use the command 'nix-shell -p git' to use git."
    exit 1
fi
echo "Git is available, continuing..."

sudo nix run nix-darwin/master#darwin-rebuild -- switch
sudo darwin-rebuild switch --flake ~/dotfiles/setup/macos#SIT-SMBP-YF0X2F

mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work
