{
  self,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  userName = "henrik";
in
{
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
 system = {
    primaryUser = "schoenfeldeh";
    stateVersion = 6;

    defaults = {
      NSGlobalDomain._HIHideMenuBar = true;
      dock.orientation = "right";
      dock.autohide = true;
      controlcenter.NowPlaying = true;
      # other macOS's defaults configuration.
      # .....
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true; 

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.zsh.enable = true;
}
