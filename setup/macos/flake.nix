{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-latest.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-24.11";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = 
    {
      self, 
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-latest,
      nix-darwin, 
      ...
    }@inputs:
  let
    pkgsStable = import nixpkgs-stable {
        system = "aarch64-darwin";
        config = {
          allowUnfree = true;
        };
      };
    pkgsLatest = import nixpkgs-latest {
      system = "aarch64-darwin";
      config = {
        allowUnfree = true;
      };
    };
      pkgsDarwin = import nix-darwin {
      system = "aarch64-darwin";
      config = {
        allowUnfree = true;
      };
    };
  in
  {
    darwinConfigurations."SIT-SMBP-YF0X2F" = nix-darwin.lib.darwinSystem {
      modules = [ 
        ./configuration.nix
        ./packages.nix
       ];
       specialArgs = { inherit inputs; };
    };
  };
}
