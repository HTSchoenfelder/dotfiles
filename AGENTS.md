# AGENTS.md

## Scope

These instructions apply to the entire repository.

## Communication and working style

- Communicate with the user in German unless asked otherwise.
- Always write authored UI labels, captions, headings, prompts, notifications, and keybinding descriptions in English, even when the user prompts in German. Preserve externally supplied text such as application and window titles.
- Always use English for code identifiers and comments.
- The user is an experienced developer. Explain Linux/NixOS/Hyprland architecture precisely without beginner-level padding.
- This is Henrik's personal power-user repository, designed exclusively for his workflow. Optimize for his explicit preferences and efficient operation rather than a general audience.
- Keep UI surfaces minimal. Do not add onboarding, usage instructions, keyboard hints, explanatory labels, or captions to launchers, selection dialogs, or overlays unless explicitly requested. Show only the information needed to make the selection.
- For architectural changes, explain the responsibility boundaries and trade-offs before making broad changes.
- Prefer small, reviewable changes over large rewrites.
- After every change or refactoring, check whether `readme.md` must be updated.
- `docs/deferred-work.md` contains postponed ideas only. Never implement or investigate an entry unless Henrik explicitly requests that specific item.
- Inspect the current repository state before editing. Do not assume that an earlier chat summary is newer than the working tree.
- Never discard or overwrite unrelated local changes.
- By default, make requested changes only in the working tree and show/review the diff. Do **not** commit, push, reset, rebase, or force-update anything unless the user explicitly asks.
- If the user explicitly asks for a commit, create one focused commit with a meaningful message after validation.
- Ask before destructive operations or changes that would materially alter boot/login behavior unless the user already requested that exact change.

## Architectural direction

The repository should become easier to understand by keeping responsibilities separate:

1. **NixOS / system services**
   - Installation and declarative OS configuration.
   - System-wide services such as NetworkManager, Bluetooth, CUPS, udisks2, Docker, libvirt, PipeWire configuration, etc.
2. **User/session services**
   - Long-running desktop-session processes that are better owned by `systemd --user` and, where appropriate, tied to `graphical-session.target`.
   - Waybar, Dunst, hyprpolkitagent, network/Bluetooth applets, Udiskie and Clipse are declared in the Nix desktop modules. Portals use D-Bus activation.
3. **Hyprland**
   - Compositor behavior only: monitors, input, look and feel, keybindings, window/workspace rules, Hyprland-specific events.
   - Avoid turning Hyprland autostart into a generic process supervisor.
4. **Shell/user tooling**
   - Zsh, Starship, CLI tooling and terminal-specific behavior should remain independent of Hyprland where possible.

Prefer declarative configuration and explicit ownership of processes.

## NixOS / login model

- The intended login flow is currently:
  `boot -> tty1 -> login/PAM -> zsh -> start-hyprland -> Hyprland`.
- `greetd` / `tuigreet` were intentionally removed.
- Do not reintroduce a display manager or automatic Hyprland start unless explicitly discussed.
- tty1 is customized for the normal `henrik` login while other TTYs retain a normal username/password login path for other users and recovery.
- PAM, systemd-logind and the normal Linux login session remain part of the design.
- The NixOS installation setup intentionally uses filesystem labels (`nixos` and `boot`) rather than machine-specific UUIDs so host configurations remain reusable.
- Be particularly cautious when editing `getty@`, PAM, boot, filesystem, or session startup configuration. Preserve a recovery path on another TTY.

## Hyprland configuration

- Hyprland is being migrated to the current **0.55+ Lua configuration API**.
- Use the current official Hyprland documentation/API when changing Lua syntax. Do not silently fall back to old Hyprlang dispatcher/config syntax.
- Entry point: `home/.config/hypr/hyprland.lua`.
- Current modular structure includes:
  - `config/environment.lua`
  - `config/input.lua`
  - `config/appearance.lua`
  - `config/catppuccin_mocha.lua`
  - `config/session.lua`
  - `config/keybindings.lua`
  - `config/application_shortcuts.lua`
  - `config/hardware_keys.lua`
  - `config/window_rules.lua`
  - `config/navigation.lua` (application definitions and navigation preferences)
  - `config/project_overlays.lua` (project overlay definitions)
  - `config/workspaces.lua`
  - `config/hosts/<host>/monitor.lua`
- Reusable behavior lives in `lib/`: window/workspace navigation, Rofi selection lifecycle, dot mode, project overlays, monitor control, media control, screenshots, application shortcut forwarding, command selection and text insertion.
- `lib/rofi_mode.lua` is a standalone Lua provider invoked by Rofi. Keep blocking process I/O out of the compositor's Lua thread.
- The active Lua configuration does not depend on `scripts/*.sh` or legacy Hyprland `.conf` files.
- `setup/nixos/setup-nixos.sh` creates the runtime `~/.config/hypr/config/monitor.lua` symlink for the selected host.
- The workspace/keybinding concept is intentionally being redesigned. Do not blindly port the old workspace setup.
- Current primary modifier is `SUPER + CTRL + ALT`.
- **Comma selection** means a Rofi selection that cycles while its shortcut is held and accepts the highlighted item when the main modifier is released.
- **Dot mode** means the Hyprland submap entered with the dot/period key while holding the main modifier.

## Desktop integration topics

- `setup/nixos/desktop-integration.nix` owns toolkit packages, dconf defaults, Dunst and the graphical `hyprpolkitagent` user service.
- `setup/nixos/desktop-session.nix` owns Waybar, network/Bluetooth applets, Udiskie and the two Clipse clipboard watchers. Do not also start these in Lua or XDG autostart.
- `config/session.lua` retains Hyprpaper and Hypridle. The current-session request to keep Hypridle paused must not be undone by tests or service migration.
- `programs.hyprland` supplies the matching Hyprland portal and GTK fallback. Portal routing stays in `home/.config/xdg-desktop-portal/hyprland-portals.conf`.
- GNOME Keyring remains the configured Secret Service and Secret portal backend. Replacing it with KeePassXC remains a separate, explicit decision.
- Hyprland manages the graphical session targets and exports session identity. Do not duplicate this with manual portal startup or a blanket environment import.
- See `docs/hyprland-desktop.md` for the Must-have and upstream default configuration audit.

Do not conflate:
- PAM (authentication/session setup),
- Polkit (authorization),
- Polkit agent (authentication UI for Polkit),
- Secret Service/keyring (credential storage),
- XDG portals (desktop capability API).

## Validation

- For Nix changes, run the narrowest useful Nix evaluation/build/check available before proposing a commit. Do not activate a new system configuration with sudo unless explicitly requested.
- For Hyprland changes, validate against the current Lua API and use targeted runtime checks where available.
- For service/session changes, inspect the relevant `systemctl --user`, `loginctl`, D-Bus, or process state rather than guessing.
- When debugging, distinguish package installation, service enablement, service activation, and runtime state.
