#! /usr/bin/env bash

sudo mv /etc/nixos /etc/nixos.bak

nix --extra-experimental-features 'nix-command flakes' flake show

sudo NIXOS_EXTRA_EXPERIMENTAL_FEATURES="nix-command flakes" nixos-rebuild switch --flake .