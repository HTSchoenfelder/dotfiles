#! /usr/bin/env bash

# nix-shell -p git

### Backup /etc/nixos
echo "Moving /etc/nixos to /etc/nixos.bak..."
read -p "(Press Enter to continue)" enter
sudo mv /etc/nixos /etc/nixos.bak
echo "Moved /etc/nixos to /etc/nixos.bak"

### Label partitions with nixos & boot
echo "Label partitions with nixos & boot"
$HOME/dotfiles/setup/nixos/label-partition.sh "boot"
$HOME/dotfiles/setup/nixos/label-partition.sh "nixos"

### Check if git is available
if ! command -v git &> /dev/null
then
    echo "Git is not available."
    exit 1
fi
echo "Git is available, continuing..."

### Applying nixos configuration
nix --extra-experimental-features 'nix-command flakes' flake show
echo "Applying nixos configuration..."
read -p "(Press Enter to continue)" enter
sudo NIXOS_EXTRA_EXPERIMENTAL_FEATURES="nix-command flakes" nixos-rebuild switch --flake .

mkdir $HOME/screenshots/
mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work
