# Hyprland desktop integration

The desktop audit uses the installed Hyprland revision
`e368c13c27a42a173b9e08fa0bf413f9f7073187` and the repository's locked Nixpkgs.
Configuration examples from newer documentation are checked against that API.

## Responsibilities

| Component | Owner and configuration |
| --- | --- |
| Compositor, input, layouts and shortcuts | `home/.config/hypr/hyprland.lua` and its Lua modules |
| Portal installation and D-Bus activation | NixOS `programs.hyprland`; Hyprland and its portal come from the same flake input |
| Portal routing | `home/.config/xdg-desktop-portal/hyprland-portals.conf` |
| Audio and capture transport | Existing NixOS PipeWire and WirePlumber services |
| Notifications and authorization UI | Upstream Dunst and hyprpolkitagent user units, enabled by `desktop-integration.nix` |
| GTK preferences | NixOS dconf defaults in `desktop-integration.nix` |
| Qt platform-theme plugins | NixOS `qt.enable` and `qt.platformTheme = "qt5ct"`, supplying both Qt 5 and Qt 6 plugins |
| Qt appearance | Existing `qt5ct` settings and matching `qt6ct/qt6ct.conf` |
| Hyprtoolkit appearance | `home/.config/hypr/hyprtoolkit.conf` |
| Login and keyring unlock | Existing tty login, PAM and GNOME Keyring configuration |

The Hyprland portal provides ScreenCast, Screenshot, GlobalShortcuts and
InputCapture. GTK provides FileChooser and Settings. The Secret portal explicitly
uses the already configured GNOME Keyring backend. KeePassXC remains an application;
enabling it as a competing Secret Service provider is a separate decision.

Polkit is the system authorization service; hyprpolkitagent only presents its
authentication UI. Neither replaces PAM, the login session, or the keyring.
The user units follow `graphical-session.target`; portals remain D-Bus activated.

Hyprland already exports its session identity and manages the graphical session
targets. The configuration therefore does not launch portals manually or import
the entire shell environment. Explicit toolkit/cursor overrides use `hl.env`'s
D-Bus export argument. GTK reads dconf, including the dark appearance preference;
`GTK_THEME`, `GTK_FONT_NAME` and `GTK_USE_PORTAL` are not used as global overrides.
Qt and GTK prefer Wayland while retaining X11 fallback.

The existing tty1 login and manual `start-hyprland` flow remain in place. Installing
packages, enabling units, activating a NixOS generation and starting a service are
distinct operations. A Lua reload cannot activate NixOS changes or remove environment
variables inherited by existing processes. Toolkit environment cleanup takes full
effect in a fresh login session after activating the NixOS configuration.

## Upstream default configuration review

The useful additions from the default configuration are the empty XWayland drag
surface focus rule and volume, microphone, brightness and playback hardware keys.
Maximize events remain suppressed for tiled navigation. These rules live in
`config/window_rules.lua`; hardware bindings live in `config/hardware_keys.lua`.

The upstream monitor, layout, workspace, application and animation choices are
examples. They do not replace the explicit host monitors, master layout, Parking
workflow or Catppuccin appearance. Optional permission enforcement is not enabled
implicitly. A new display manager or session wrapper is not required.

The Must-have components are covered: a notification daemon, PipeWire/WirePlumber,
the compositor portal and GTK fallback, a graphical Polkit agent, Wayland support
for both Qt versions, and the existing font packages.

## Screenshots

`mainMod + period` enters a waiting submap. `Q` captures a region; `W` captures the
active monitor. Both work with the main modifier held or released. Escape and
unrecognized keys cancel. The submap resets before Hyprshot starts, and entering it
cancels any pending navigation picker. Images use `HYPRSHOT_DIR` (`~/screenshots`).

## Validation

- Lua behavior tests cover screenshot selection/cancellation alongside navigation.
- Real compositor key events verify both modifier states and cancellation.
- A raw Hyprshot capture is checked as a PNG matching the active output's dimensions.
- Nix evaluation covers all three host configurations and their assertions.
- The generated dconf database and assembled user-unit tree are built; the Dunst
  and Polkit units are checked with `systemd-analyze --user verify`.
- The running Settings portal reports dark appearance (`1`), and the portal exposes
  FileChooser, ScreenCast and Secret after reloading its routing configuration.
  This does not substitute for an application-specific browser screen-sharing test.
- `hypridle` remains paused in the current session at the user's request.

## Sources

- [Hyprland Must-have](https://wiki.hypr.land/useful-utilities/must-have/)
- [Default Lua configuration at the installed revision](https://github.com/hyprwm/Hyprland/blob/e368c13c27a42a173b9e08fa0bf413f9f7073187/example/hyprland.lua)
- [Hyprland desktop portal](https://wiki.hypr.land/hypr-ecosystem/user/xdg-desktop-portal-hyprland/)
- [Hyprland on NixOS](https://wiki.hypr.land/nix/installing-hyprland-on-nixos/)
- [Systemd integration](https://wiki.hypr.land/configuring/extra/systemd/)
- [Environment variables](https://wiki.hypr.land/configuring/core/environment-variables/)
- [Submaps](https://wiki.hypr.land/configuring/core/binds/submaps/)
- [hyprpolkitagent](https://wiki.hypr.land/hypr-ecosystem/user/hyprpolkitagent/)

NixOS module behavior is verified against the locked source, particularly
`programs/wayland/hyprland.nix`, `programs/wayland/wayland-session.nix`,
`config/xdg/portal.nix`, `config/qt.nix` and `programs/dconf.nix`.
