#! /usr/bin/env bash

if [ "$#" -eq 1 ]; then
  configuration=$1
else
  read -p "Enter the configuration: " configuration
fi

export NIXOS_EXTRA_EXPERIMENTAL_FEATURES="nix-command flakes" 
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
if ! command -v git &>/dev/null; then
    echo "Git is not available."
    echo "Use the command 'nix-shell -p git' to use git."
    exit 1
fi
echo "Git is available, continuing..."

### Applying nixos configuration
nix --extra-experimental-features 'nix-command flakes' flake show
echo "Applying nixos configuration..."
read -p "(Press Enter to continue)" enter
sudo nixos-rebuild switch --flake .#$configuration

ln -sf ~/dotfiles/home/.config/hypr/$configuration/monitor.conf ~/.config/hypr/hyprland.monitor.conf

mkdir $HOME/screenshots/
mkdir -p ~/projects/dev
mkdir -p ~/projects/temp
mkdir -p ~/projects/work

bat cache --build

echo "Copying 'stow home --no-folding' into clipboard..."
echo "stow home --no-folding" | wl-copy