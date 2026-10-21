{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/release-25.05";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgsStable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit pkgsStable; };
        modules = [
          ./configuration.nix
          ./packages.nix
        ];
      };
    };
}
