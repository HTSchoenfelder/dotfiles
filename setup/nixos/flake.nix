{
  inputs = {
    nixpkgs-latest.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "git+https://github.com/nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs =
    {
      nixpkgs-latest,
      nixpkgs-stable,
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
      mkHost =
        hardwareModule: hostModule:
        nixpkgs-latest.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgsStable;
          };
          modules = [
            ./configuration.nix
            hardwareModule
            hostModule
            ./packages.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost ./configurations/desktop/hardware.nix ./configurations/desktop/host.nix;
        notebook = mkHost ./configurations/notebook/hardware.nix ./configurations/notebook/host.nix;
        qemu = mkHost ./configurations/qemu/hardware.nix ./configurations/qemu/host.nix;
      };
    };
}
