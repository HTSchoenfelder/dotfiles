#! /bin/bash

sudo mv /etc/nixos/hardware-configuration.nix ~/dotfiles/setup/nixos/hardware-configuration.nix
sudo chown -R $USER:users ~/dotfiles/setup/nixos/hardware-configuration.nix
sudo mv /etc/nixos /etc/nixos.bak