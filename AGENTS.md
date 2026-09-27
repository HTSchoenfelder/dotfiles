# AGENTS.md

These instructions apply to the entire repository.

## Working rules

- Communicate with Henrik in German unless asked otherwise.
- Write UI text, documentation headings, shortcut descriptions, code identifiers
  and comments in English. Preserve external application and window titles.
- This is a personal power-user repository. Optimize for Henrik's workflow and
  keep launchers, choosers and overlays free of onboarding text and keyboard hints.
- Inspect the repository and current diff before editing. Preserve unrelated work.
- Prefer small, reviewable changes. Do not commit, push, reset or rebase unless
  explicitly requested.
- Update every affected document and shortcut reference with each behavior or
  architecture change. Always inspect `readme.md`.
- `docs/deferred-work.md` contains postponed work. Only act on an entry when Henrik
  explicitly requests it.
- Explain ownership boundaries and material trade-offs before broad architecture
  changes.

## Product and architecture

Hyprland defines the reference workflow. macOS should preserve its shortcut shapes,
modifier combinations, action semantics and selection lifecycle wherever reliable.
Behavioral parity matters more than using identical platform mechanisms. Document
any deliberate difference that affects muscle memory.

The planned macOS architecture is:

- Hammerspoon owns global input, held-key state, Comma Selection, Dot Mode,
  `hs.chooser`, application intentions, MRU state and MIDI integration.
- AeroSpace owns the window tree, geometry, workspaces, monitor assignment and
  window operations. It has no regular workflow bindings.
- Hammerspoon invokes AeroSpace asynchronously and decides master/stack intent. It
  must not remain a second geometry engine after the migration.

The current macOS implementation remains Hammerspoon-only. The target architecture
is in `docs/macos-window-management.md`; the complete implementation task is in
`aerospace-migration.md`.

System and session ownership stays explicit:

- NixOS owns packages and system services.
- `systemd --user` owns long-running desktop processes.
- Hyprland owns compositor behavior, bindings, window rules and compositor events.
- Shell and terminal behavior stays independent of Hyprland where practical.

See `docs/hyprland-desktop.md` for the current service, portal and toolkit ownership.

## Hyprland

- Use the installed Hyprland 0.55+ Lua API and current official documentation.
  Entry point: `home/.config/hypr/hyprland.lua`.
- Keep reusable behavior in `home/.config/hypr/lib/`; the active configuration must
  not depend on legacy `.conf` fragments or `scripts/*.sh`.
- Keep blocking process I/O out of the compositor Lua thread.
- `setup/nixos/setup-nixos.sh` creates the host-specific `config/monitor.lua`
  symlink.
- `mainMod` is `SUPER + CTRL + ALT`.
- **Comma Selection** cycles in Rofi and accepts on `mainMod` release.
- **Dot Mode** is the submap entered with `mainMod + period`.
- **Terminal Workspace** is workspace 1 (``) on the primary display.
- **Display Workspace** is workspace 2 (`󰍹`) on the secondary display.
- **Parking Workspace** is workspace 10 (`󰮍`).
- Hyprpaper and Hypridle remain compositor-session processes. Do not resume the
  currently paused Hypridle process unless Henrik requests it.

## System guardrails

- The login path is `tty1 -> login/PAM -> zsh -> start-hyprland -> Hyprland`.
  Do not add a display manager or automatic compositor start without discussion.
- Preserve normal login and recovery on the other TTYs when touching getty, PAM,
  boot or session startup.
- Do not duplicate services between Hyprland, XDG autostart and systemd.
- Do not manually start portals; they use the configured packages and D-Bus
  activation. GNOME Keyring remains the Secret Service backend.
- Do not activate a NixOS generation with `sudo` unless explicitly requested.

## Validation

- Run the narrowest meaningful checks for the changed area.
- For Hyprland changes, validate Lua syntax, behavioral tests and the installed
  compositor API where available.
- For Nix and service changes, evaluate the relevant configuration and inspect real
  unit/session state rather than inferring it.
- Run `git diff --check` and review the final diff before reporting completion.
