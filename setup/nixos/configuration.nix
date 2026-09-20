{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  userName = "henrik";
  userDescription = "Henrik";
  hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  hyprlandPortalPackage =
    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  # tty1 is the regular interactive login for Henrik: skip the username prompt,
  # but keep the normal PAM password authentication. Other TTYs remain standard
  # username/password logins so another account can always be used there.
  consoleLogin = pkgs.writeShellScript "console-login" ''
    if [ "$TTY" = "tty1" ]; then
      exec ${pkgs.util-linux}/bin/agetty \
        --login-program ${pkgs.shadow}/bin/login \
        --login-options '-p -- ${userName}' \
        --skip-login \
        --issue-file /etc/issue:/etc/issue.d:/run/issue:/run/issue.d \
        --noclear --keep-baud "$TTY" 115200,38400,9600 "$TERM"
    fi

    exec ${pkgs.util-linux}/bin/agetty \
      --login-program ${pkgs.shadow}/bin/login \
      --issue-file /etc/issue:/etc/issue.d:/run/issue:/run/issue.d \
      --noclear --keep-baud "$TTY" 115200,38400,9600 "$TERM"
  '';
in
{
  users.users."${userName}" = {
    isNormalUser = true;
    description = userDescription;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "dialout"
    ];
    packages = with pkgs; [ ];
  };

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
    timeout = 2; 
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprlandPackage;
    portalPackage = hyprlandPortalPackage;
  };

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  networking.networkmanager.enable = true;
  networking.hostName = "nixos";

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # services.gnome.gnome-keyring.enable = true;
  services.pcscd.enable = true;

  # Console login styling. tty1 is optimized for the normal Henrik login;
  # Ctrl+Alt+F2 (and the other TTYs) keep the regular user-name prompt.
  services.getty = {
    greetingLine = ":: NixOS :: \\n :: \\l ::";
    helpLine = "tty1: henrik  |  Ctrl+Alt+F2: login as another user";
  };

  systemd.services."getty@".serviceConfig.ExecStart = lib.mkForce [
    ""
    consoleLogin
  ];

  console = {
    font = "Lat2-Terminus16";
    colors = [
      "1e1e2e"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "cba6f7"
      "94e2d5"
      "bac2de"
      "585b70"
      "eba0ac"
      "a6e3a1"
      "f9e2af"
      "74c7ec"
      "cba6f7"
      "89dceb"
      "cdd6f4"
    ];
  };

  # Scanning / Printing (CUPS)
  services.printing = {
    enable = true;
    browsed = {
      enable = false;
    };
    drivers = with pkgs; [
      hplip
      gutenprint
      foo2zjs
    ];
  };
  hardware.sane.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.gvfs.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.shells = [ pkgs.zsh ];
  users.defaultUserShell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.firefox = {
    enable = true;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  security.polkit.enable = true;
  services.udisks2.enable = true;

  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry#custom-nix-path-and-flake-registry-1
  # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

  # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  # https://github.com/NixOS/nix/issues/9574
  nix.settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";
  systemd.tmpfiles.rules = [
    "r /root/.nix-defexpr/channels"
    "r /nix/var/nix/profiles/per-user/root/channels"
  ];

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  programs.ssh = {
    startAgent = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;
  environment.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_9_0}";
    NIXOS_OZONE_WL = "1";
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      icu76
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };

  networking.firewall.allowedTCPPorts = [ ];
  networking.firewall.allowedUDPPorts = [ ];
  networking.firewall.enable = true;

  system.stateVersion = "24.11";
}
