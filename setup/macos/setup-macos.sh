#!/usr/bin/env bash

set -euo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ "$#" -eq 1 ]; then
  configuration=$1
else
  read -r -p "Enter the configuration [macbook]: " configuration
  configuration=${configuration:-macbook}
fi

# Check if Nix is available.
if ! command -v nix &>/dev/null; then
    echo "Nix is not available."
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate
fi

# Check if Homebrew is available.
if ! command -v brew &>/dev/null; then
    echo "Homebrew is not available."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check if Git is available.
if ! command -v git &>/dev/null; then
    echo "Git is not available."
    echo "Use the command 'nix-shell -p git' to use git."
    exit 1
fi
echo "Git is available, continuing..."

brew bundle --file "$script_directory/Brewfile"
sudo nix run nix-darwin/master#darwin-rebuild -- switch \
    --flake "$script_directory#$configuration"

mkdir -p "$HOME/projects/dev"
mkdir -p "$HOME/projects/temp"
mkdir -p "$HOME/projects/work"
