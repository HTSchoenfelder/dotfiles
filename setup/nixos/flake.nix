{
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";
    nixpkgs-latest.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-24.05";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-latest,
      home-manager,
      ...
    }@inputs:
    let
      pkgsStable = import nixpkgs-stable {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
        };
      };
      pkgsLatest = import nixpkgs-latest {
        system = "x86_64-linux";
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs pkgsStable pkgsLatest;
        };
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./hardware-desktop.nix
          ./packages.nix
          home-manager.nixosModules.home-manager
        ];
      };
    };
}
