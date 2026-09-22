# AGENTS.md

## Scope

These instructions apply to the entire repository.

## Communication and working style

- Communicate with the user in German unless asked otherwise.
- The user is an experienced developer. Explain Linux/NixOS/Hyprland architecture precisely without beginner-level padding.
- For architectural changes, explain the responsibility boundaries and trade-offs before making broad changes.
- Prefer small, reviewable changes over large rewrites.
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
   - Examples under consideration: Waybar, Dunst, hyprpolkitagent, portals/session helpers, and similar daemons.
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
  - `config/env.lua`
  - `config/input.lua`
  - `config/look-and-feel.lua`
  - `config/mocha.lua`
  - `config/autostart.lua`
  - `config/keybindings.lua`
  - `config/hosts/<host>/monitor.lua`
- `setup/nixos/setup-nixos.sh` creates the runtime `~/.config/hypr/config/monitor.lua` symlink for the selected host.
- Old Hyprland `.conf` files intentionally remain as migration reference/backup. Do not delete or bulk-migrate them unless explicitly requested.
- The workspace/keybinding concept is intentionally being redesigned. Do not blindly port the old workspace setup.
- Current primary modifier is `SUPER + CTRL + ALT`.

## Desktop integration topics

These are intentionally being reviewed rather than treated as settled:

- XDG Desktop Portal / `xdg-desktop-portal-hyprland` plus GTK fallback.
- Polkit versus the graphical Polkit authentication agent; `hyprpolkitagent` is a likely choice but should be integrated deliberately.
- Freedesktop Secret Service provider: GNOME Keyring versus KeePassXC integration is still an open design decision.
- Whether current Hyprland Lua autostart entries should move to `systemd --user`.

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
