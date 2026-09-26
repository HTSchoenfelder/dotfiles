{ config, pkgs, ... }:
let
  sessionService = description: command: {
    inherit description;
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      Type = "exec";
      ExecStart = command;
      Restart = "on-failure";
      RestartSec = 2;
      Slice = "session.slice";
    };
  };

  # Clipse's Wayland listener launches these two watchers and exits. Supervise
  # the watchers directly so their lifetime and failures remain visible.
  clipboardService =
    mimeType:
    (sessionService "Clipse clipboard listener (${mimeType})" "${pkgs.wl-clipboard}/bin/wl-paste --type ${mimeType} --watch ${pkgs.clipse}/bin/clipse -wl-store")
    // {
      path = [
        pkgs.wl-clipboard
        pkgs.bash
        pkgs.which
        config.programs.hyprland.package
      ];
    };

  disabledAutostart = ''
    [Desktop Entry]
    Hidden=true
  '';
in
{
  programs.waybar.enable = true;
  programs.nm-applet.enable = true;

  systemd.user.services = {
    # These GUI tools launch user-configured programs. Keep the session PATH
    # exported by Hyprland instead of replacing it with a minimal daemon PATH.
    waybar = {
      enableDefaultPath = false;
      # The upstream unit uses a bare kill command; resolve it declaratively.
      serviceConfig.ExecReload = [
        ""
        "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID"
      ];
    };
    nm-applet.enableDefaultPath = false;

    # services.blueman already installs the D-Bus service and upstream unit.
    blueman-applet = {
      enableDefaultPath = false;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 2;
        Slice = "session.slice";
      };
    };

    udiskie = (sessionService "Removable media automounter" "${pkgs.udiskie}/bin/udiskie --tray") // {
      enableDefaultPath = false;
    };
    clipse-text = clipboardService "text";
    clipse-images = clipboardService "image/png";
  };

  # Explicit user services own these applets, including D-Bus activation for
  # Blueman. Suppress the second startup path through the XDG generator.
  environment.etc = {
    "xdg/autostart/blueman.desktop".text = disabledAutostart;
    "xdg/autostart/nm-applet.desktop".text = disabledAutostart;
  };
}
