#! /usr/bin/env bash

# nix-shell -p git

echo "Moving /etc/nixos to /etc/nixos.bak..."
read -p "(Press Enter to continue)" enter

sudo mv /etc/nixos /etc/nixos.bak
echo "Moved /etc/nixos to /etc/nixos.bak"

if ! command -v git &> /dev/null
then
    echo "Git is not available."
    exit 1
fi
echo "Git is available, continuing..."

nix --extra-experimental-features 'nix-command flakes' flake show

echo "Applying nixos configuration..."
read -p "(Press Enter to continue)" enter

sudo NIXOS_EXTRA_EXPERIMENTAL_FEATURES="nix-command flakes" nixos-rebuild switch --flake .