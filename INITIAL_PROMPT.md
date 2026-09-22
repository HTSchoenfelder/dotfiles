# Initial Codex handoff prompt

You are continuing work on my personal NixOS/Hyprland dotfiles repository. Read `AGENTS.md` first, then inspect the repository and recent Git history before changing anything.

## How I want to work

I want to understand the architecture, not just accumulate fixes. For larger changes, first explain which component is responsible and why the change belongs there.

Please default to this workflow:

1. inspect the current state,
2. explain the relevant architecture,
3. propose a focused change,
4. edit locally if I ask,
5. show/review the diff and run appropriate checks,
6. **do not commit unless I explicitly say to commit**.

Do not delete old migration/reference files merely because they are currently unused.

## Overall vision

I want a clean, modular, declarative NixOS + Hyprland setup with clear responsibility boundaries:

- NixOS owns packages, system configuration and system-wide services.
- `systemd --user` should own suitable long-running user/session daemons.
- Hyprland Lua should primarily describe compositor behavior, not act as a generic service supervisor.
- Shell tooling such as Zsh/Starship should work independently of Hyprland, including on a plain TTY.
- Configuration should remain reusable across multiple hosts (`desktop`, `notebook`, `qemu`) rather than becoming machine-specific.
- Prefer current upstream documentation and APIs over legacy syntax or cargo-cult configuration.

## What has already been implemented

### Hyprland Lua migration

The old Hyprland configuration was historically split across `.conf` files. A migration to the Hyprland 0.55+ Lua API has started.

Current entry point:

`home/.config/hypr/hyprland.lua`

It currently requires modular files for:

- monitor
- environment
- input
- look and feel
- autostart
- keybindings

Host-specific monitor files live under:

`home/.config/hypr/config/hosts/<host>/monitor.lua`

The NixOS setup script creates:

`~/.config/hypr/config/monitor.lua`

as a symlink to the selected host's monitor module.

The old `.conf` files are intentionally still present as reference/backup during migration.

Relevant migration commits include:

- `e90a277` — migrate Hyprland base config to Lua modules
- `30878eb` — migrate Hyprland autostart to Lua
- `9231b35` — add minimal Hyprland Lua keybindings
- `bb7c162` — add basic Hyprland window and Chrome bindings
- `ed1fc7f` — fix Chrome focus binding for Hyprland Lua dispatcher

### Current minimal keybindings

The main modifier is:

`SUPER + CTRL + ALT`

Current intended bindings are intentionally minimal:

- MainMod + R: Wofi launcher
- MainMod + J: Kitty with `START_ZELLIJ=1`
- MainMod + W: close active window
- MainMod + L: focus Chrome if it exists, otherwise launch `google-chrome-stable`

The old workspace/keybinding concept should **not** be migrated wholesale. I want to rethink it.

### Current Hyprland autostart

`config/autostart.lua` currently starts several processes from `hl.on("hyprland.start", ...)`, including:

- Waybar
- Dunst
- hyprpaper
- hypridle
- clipse
- udiskie
- Synology Drive after a delay
- cursor dconf settings
- blueman-applet
- nm-applet
- arduino-create-agent
- a Hyprland event-listener script
- `dbus-update-activation-environment --systemd --all`

This is **not necessarily the desired final architecture**.

A duplicate Waybar was observed after a Hyprland reload: one Waybar was already running and another appeared later. Treat this as an unresolved symptom and investigate ownership/lifecycle rather than simply adding process-kill hacks.

### Login/session model

Initially the machine used `greetd + tuigreet`. That was first corrected to start Hyprland through `start-hyprland`, then deliberately removed entirely.

Relevant commits:

- `87bc37d` — start Hyprland through start-hyprland
- `5d8740d` — remove greetd and use TTY login for Hyprland
- `f31068f` — style console login and preselect tty1 user

The intended model is now:

`boot -> tty1 -> login -> PAM -> systemd-logind session -> zsh -> start-hyprland -> Hyprland`

tty1 is customized so the normal user `henrik` is preselected and only the password is requested. Other TTYs should retain normal username/password login so another user or recovery login remains possible.

The console also has a Terminus console font and a Catppuccin-Mocha-like 16-color palette.

### NixOS installation/filesystem direction

During a fresh install there was a mismatch because the installer initially created Btrfs while the repository expected ext4 and filesystem labels.

The intended reusable model is labels rather than UUIDs:

- root label: `nixos`
- EFI/boot label: `boot`

`setup/nixos/setup-nixos.sh` labels the partitions and applies the selected flake configuration.

Do not replace these labels with host-specific UUIDs without discussing the portability trade-off.

### VS Code / Lua

The VS Code Lua language server complained about the injected Hyprland global `hl`. Repository settings were updated so `hl` is recognized as a global alongside Hammerspoon's `hs`.

At runtime `hl` is supplied by Hyprland; it should not be manually defined in the Lua config merely to satisfy the editor.

## Concepts we have already clarified

I want future changes to preserve these distinctions:

### systemd

There is a system-wide systemd (PID 1) and a per-user `systemd --user` manager.

System-wide services and user/session services should not be mixed casually.

### TTY / getty / login / PAM / session

- TTY: terminal device such as `/dev/tty1`.
- getty/agetty: prepares the TTY and invokes login.
- login: performs a user login through PAM.
- PAM: authentication/account/session framework.
- `pam_systemd` / systemd-logind: registers the user login session.
- Zsh starts after successful login.
- Hyprland is then explicitly started with `start-hyprland`.

Multiple login sessions are possible. Sessions of the same Unix user are organizationally separate but are **not** strong security isolation because they share the same UID, home directory and much user-level infrastructure.

### XDG Desktop Portal

`xdg-desktop-portal` is the generic D-Bus frontend for desktop capabilities. Backend implementations provide desktop/compositor-specific functionality.

Current NixOS configuration enables the Hyprland portal and also GTK portal fallback. Hyprland's backend is particularly relevant for things such as screencasting; GTK can provide generic desktop dialogs/functions such as file chooser support.

There was a Hyprland “Getting started” screen where XDG Desktop Portal appeared missing initially and later running. Do not assume “package installed” equals “service active”; inspect runtime state and activation.

### Polkit

Polkit is authorization: “may this user perform this privileged action?”

It is different from PAM.

The system currently has `security.polkit.enable = true`, but the Hyprland onboarding screen showed that no graphical authentication agent was running.

A likely future step is to add `hyprpolkitagent`, preferably with clear ownership/lifecycle rather than blindly launching another process from Hyprland autostart.

### Secret Service / GNOME Keyring / KeePassXC

VS Code/Electron reported that the OS keyring was unavailable and mentioned GNOME/libsecret.

The important model is:

`application -> libsecret / Freedesktop Secret Service API -> org.freedesktop.secrets provider`

GNOME Keyring is only one provider. KeePassXC can also provide the Freedesktop Secret Service API.

No final provider decision has been made yet. I already use KeePassXC, so using its Secret Service integration is an attractive option, but I also want to understand the implications compared with GNOME Keyring and PAM-based auto-unlock.

Useful runtime diagnostic:

`busctl --user status org.freedesktop.secrets`

## Important open design/refactoring topics

Please treat these as open questions, not predetermined implementation instructions:

1. Refactor `setup/nixos/configuration.nix` into understandable modules by responsibility.
2. Decide which current Hyprland autostart processes should instead be `systemd --user` services.
3. Investigate the duplicate-Waybar-on-reload behavior as part of that lifecycle cleanup.
4. Add/configure a Polkit authentication agent cleanly.
5. Verify XDG portal startup, backend selection and graphical-session integration.
6. Choose and integrate a Secret Service provider (KeePassXC vs GNOME Keyring or another deliberate option).
7. Continue redesigning Hyprland keybindings/workspaces rather than mechanically porting the old config.
8. Optionally refine the TTY/Zsh presentation further; Zsh/Starship should remain useful before Hyprland starts.
9. Keep host-specific monitor configuration clean and portable.

## First thing to do in this Codex session

Do not edit anything yet.

Please:

1. read `AGENTS.md`,
2. inspect `git status` and the recent Git log,
3. inspect the current NixOS and Hyprland configuration,
4. compare the repository with this handoff,
5. tell me whether anything in this handoff is already stale or inconsistent,
6. give me a concise architectural map of the current setup and identify the most useful next refactoring boundary.

After that I will decide what we change first.
