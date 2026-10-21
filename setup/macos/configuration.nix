{
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;

  system = {
    primaryUser = "schoenfeldeh";
    stateVersion = 6;

    defaults = {
      dock.orientation = "bottom";
      controlcenter.NowPlaying = true;
    };
  };

  # Allow Touch ID for sudo authentication.
  security.pam.services.sudo_local.touchIdAuth = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.zsh.enable = true;

  launchd.agents.colima-daemon = {
    serviceConfig = {
      Label = "io.github.abiosoft.colima";
      RunAtLoad = true;
      KeepAlive = true;

      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
        "--runtime"
        "docker"
        "--cpu"
        "2"
        "--memory"
        "4"
        "--disk"
        "30"
      ];
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.log";
    };
  };
}
