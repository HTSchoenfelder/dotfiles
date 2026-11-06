{ pkgs, lib, ... }:
let
  yaziFilePicker = pkgs.writeShellApplication {
    name = "yazi-file-picker";
    runtimeInputs = with pkgs; [
      coreutils
      kitty
      yazi
    ];
    text = ''
      multiple="$1"
      directory="$2"
      save="$3"
      path="$4"
      output="$5"
      debug="$6"
      directory_output="''${output}.directory"
      yazi_environment=()

      if [[ "$debug" == 1 ]]; then
        set -x
      fi

      cleanup() {
        rm -f -- "$directory_output"
      }
      trap cleanup EXIT

      if [[ "$save" == 1 ]]; then
        title="Save File"
        yazi_environment=(
          YAZI_SAVE_OUTPUT="$output"
          YAZI_SAVE_NAME="$(basename -- "$path")"
        )
        yazi_arguments=("$(dirname -- "$path")")
      elif [[ "$directory" == 1 ]]; then
        title="Select Folder"
        yazi_arguments=(--chooser-file="$output" --cwd-file="$directory_output" "$path")
      elif [[ "$multiple" == 1 ]]; then
        title="Open Files"
        yazi_arguments=(--chooser-file="$output" "$path")
      else
        title="Open File"
        yazi_arguments=(--chooser-file="$output" "$path")
      fi

      kitty \
        --class yazi-file-picker \
        --title "$title" \
        env "''${yazi_environment[@]}" yazi "''${yazi_arguments[@]}"

      if [[ "$directory" == 1 && ! -s "$output" && -s "$directory_output" ]]; then
        cp -- "$directory_output" "$output"
      fi
    '';
  };
in
{
  # programs.hyprland already supplies matching Hyprland/GTK portal packages,
  # D-Bus integration, dconf support and the graphical session target.
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];

  # The portal invokes the wrapper on demand; it is not a session daemon.
  # The Yazi save plugin returns a destination path without creating a file.
  environment.etc."xdg/xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${yaziFilePicker}/bin/yazi-file-picker
    create_help_file=0
    default_dir=$HOME
    open_mode=suggested
    save_mode=suggested
  '';

  # The NixOS module supplies both qt5ct and qt6ct and their plugin search paths.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  environment.systemPackages = with pkgs; [
    hyprpolkitagent
    qt6.qtwayland
    adwaita-icon-theme
  ];

  # Reuse upstream units and let the graphical session own their lifetime.
  systemd.packages = with pkgs; [
    dunst
    hyprpolkitagent
  ];
  services.dbus.packages = with pkgs; [
    dunst
    hyprpolkitagent
  ];
  systemd.user.services.dunst = {
    wantedBy = [ "graphical-session.target" ];
    # Notification actions use the session's Rofi and xdg-open commands.
    enableDefaultPath = false;
  };
  systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];

  # GTK and the Settings portal read GSettings/dconf, including libadwaita's
  # color preference. Keep these as defaults so deliberate user overrides work.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Adwaita-dark";
        icon-theme = "Adwaita";
        font-name = "Agave Nerd Font 12";
        monospace-font-name = "Agave Nerd Font 12";
        cursor-theme = "catppuccin-mocha-mauve-cursors";
        cursor-size = lib.gvariant.mkInt32 28;
      };
    }
  ];
}
