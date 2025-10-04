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
  nix.enable = false;

 system = {
    primaryUser = "schoenfeldeh";
    stateVersion = 6;

    defaults = {
      NSGlobalDomain._HIHideMenuBar = false;
      dock.orientation = "bottom";
      dock.autohide = false;
      controlcenter.NowPlaying = true;
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true; 

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.zsh.enable = true;
  
 launchd.agents."colima-daemon" = {
    serviceConfig = {
      Label = "io.github.abiosoft.colima";
      RunAtLoad = true;
      KeepAlive = true;

      # Add this EnvironmentVariables block
      EnvironmentVariables = {
        DOCKER_HOST = "unix://${pkgs.docker}/var/run/docker.sock";
      };

      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--runtime" "docker" # Explicitly set runtime
        "--cpu" "2"
        "--memory" "4"
        "--disk" "30"
      ];
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.log";
    };
  };

}
