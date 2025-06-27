# sudo nix run nix-darwin/master#darwin-rebuild -- switch 
{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      environment.systemPackages = with pkgs;
        [
          darwin-rebuild
          kitty
          vim
          git
          vscode
          stow
          stackit-cli
          utm
          fzf
          zoxide
          direnv
          starship
          eza
          yazi
          podman
          podman-desktop
          kubectl 
          direnv
          terraform
          zellij
          neovim
          tmux
          nodejs
          bat
          yabai
          aerospace
          keepassxc
          spotify
          obsidian
          gnumake
          logseq
        ];

      nix.settings.experimental-features = "nix-command flakes";
      nixpkgs.config.allowUnfree = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#SIT-SMBP-YF0X2F
    darwinConfigurations."SIT-SMBP-YF0X2F" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
      system.defaults.NSGlobalDomain._HIHideMenuBar = true;
    };
  };
}
