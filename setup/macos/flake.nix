{
  inputs = {
    nixpkgs-latest.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-latest";
  };

  outputs =
    {
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
