#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
  configuration=$1
else
  read -p "Enter the configuration: " configuration
fi

### Check if git is available
if ! command -v git &>/dev/null; then
    echo "Git is not available."
    echo "Use the command 'nix-shell -p git' to use git."
    exit 1
fi
echo "Git is available, continuing..."

curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

sudo nix run nix-darwin/master#darwin-rebuild -- switch

mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work
