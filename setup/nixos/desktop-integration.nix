{ pkgs, lib, ... }:
{
  # programs.hyprland already supplies matching Hyprland/GTK portal packages,
  # D-Bus integration, dconf support and the graphical session target.
  xdg.portal.xdgOpenUsePortal = true;

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
  systemd.user.services.dunst.wantedBy = [ "graphical-session.target" ];
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
