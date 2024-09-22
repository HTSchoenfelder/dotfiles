#!/bin/sh

CONFIG_CONTENT=$(cat <<EOF
{ config, pkgs, ... }:

{
  imports =
    [
      /etc/nixos/hardware-configuration.nix
      /home/henrik/dotfiles/configuration.nix
    ];
}
EOF
)

echo "$CONFIG_CONTENT" > /etc/nixos/configuration.nix