{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-25.05";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, nix-darwin, ... }@inputs:
  let
    system = "aarch64-darwin";
    pkgsStable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    darwinConfigurations."SIT-SMBP-YF0X2F" = nix-darwin.lib.darwinSystem {
      inherit system; 
      modules = [
        ./configuration.nix
        ./packages.nix
      ];
      specialArgs = { inherit inputs pkgsStable; };
    };
  };
}