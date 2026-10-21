{
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";
    nixpkgs-latest.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-24.11";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-latest,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      mkPkgs =
        source:
        import source {
          inherit system;
          config.allowUnfree = true;
        };
      pkgsStable = mkPkgs nixpkgs-stable;
      pkgsLatest = mkPkgs nixpkgs-latest;
      mkHost =
        hardwareModule:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgsStable pkgsLatest;
          };
          modules = [
            ./configuration.nix
            hardwareModule
            ./packages.nix
            home-manager.nixosModules.home-manager
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost ./configurations/desktop/hardware.nix;
        notebook = mkHost ./configurations/notebook/hardware.nix;
        qemu = mkHost ./configurations/qemu/hardware.nix;
      };
    };
}
