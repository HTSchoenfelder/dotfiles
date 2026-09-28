# Dotfiles

Personal NixOS, Hyprland and macOS configuration for Henrik's desktop workflow.

## Workflow goal

Hyprland is the reference environment for building Henrik's keyboard-driven
workflow. The macOS configuration reproduces that interaction model as closely as
its native APIs allow so the same muscle memory applies on both systems. Shortcut
shapes, modifier combinations, navigation semantics and selection flows should
remain aligned. The underlying mechanisms may differ: Hyprland's native master
layout and AeroSpace's container tree can implement the same user-facing operation.

Reliable platform-native behavior takes precedence when exact parity would be
fragile. Intentional differences that affect muscle memory must stay explicit and
documented.

The macOS implementation keeps Hammerspoon as the only input and UI layer and uses
AeroSpace as the window-management backend. Hammerspoon owns all shortcuts, modes,
choosers, application intentions, MRU state and MIDI integration. It invokes the
AeroSpace CLI asynchronously for tree, workspace, monitor, focus, move and swap
operations; Hammerspoon no longer places managed windows directly. See the
[macOS window-management architecture](docs/macos-window-management.md) for the
implemented boundaries. The original implementation brief remains in
[`aerospace-migration.md`](aerospace-migration.md).

The interaction model is shared, while the requested split ratio intentionally
differs: Hyprland currently uses a 70/30 master/stack split and the macOS target
uses 1:1.

## macOS / Hammerspoon quick reference

`mainMod` = `Option + Control + Command`. Application shortcuts use bundle IDs and
the Hammerspoon MRU history. Normal activation moves the selected window to the
focused workspace and moves the other tiled windows there to Parking. Holding `F`
keeps the current layout and adds the selected window to the right stack. Holding
`A` always opens the instance chooser, including for a single instance.

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/I/;/O/U` | Activate Kitty / VS Code / Chrome / Google Chat / Obsidian / KeePassXC / Spotify and park other workspace windows |
| `mainMod + F + app key` | Add the selected application to the right stack |
| `mainMod + A + app key` | Select an application window before placing it |
| `mainMod + P` | Select any managed window by recent focus; hold `F` to add it to the stack |
| `mainMod + ,` / `mainMod + Shift + ,` | Cycle windows forward/backward; release `mainMod` to accept |
| `mainMod + A + ,` | Cycle through windows of the focused application |
| `mainMod + G` / `mainMod + Shift + G` | Cycle workspaces by recent focus; release `mainMod` to accept |
| `mainMod + M` | Focus the next tiled window on the active workspace |
| `mainMod + N` | Rotate positions while retaining focus on the visual slot |
| `mainMod + H` | Switch between Terminal Workspace 1 and Display Workspace 2 |
| `mainMod + W` | Close the focused window |
| `mainMod + R` | Toggle the native application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |
| `mainMod + Shift + M` | Toggle the RØDECaster mute state |

Application, window, workspace and comma selection use the same compact
`hs.chooser` presentation. AeroSpace workspaces replace native Mission Control
Spaces for this workflow: Terminal is `1` (``), Display is `2` (`󰍹`) and Parking
is `10` (`󰮍`). Workspace 2 prefers the secondary display and falls back to the
main display when only one monitor is connected.

Managed layouts use one full-size window, a 1:1 left/right split for two windows,
and a left master with a vertical right stack for three or more windows.

## Hyprland quick reference

`mainMod` = `Super + Ctrl + Alt`. Application navigation reuses the most recently
focused matching window or starts the app. Other windows on the active workspace
move to Parking (`󰮍`). Hold `F` to keep them and place the target in the master
stack. Hold `A` to choose an existing instance.

| Shortcut | Action |
| --- | --- |
| `mainMod + J` | Kitty with Zellij |
| `mainMod + K` | VS Code |
| `mainMod + L` | Chrome |
| `mainMod + I` | Google Chat |
| `mainMod + ;` | Obsidian |
| `mainMod + O` | KeePassXC |
| `mainMod + U` | Spotify |
| `mainMod + F + app key` | Keep the current layout and add the selected app to its stack |
| `mainMod + P` | Select any window by recent focus |
| `mainMod + ,` / `mainMod + Shift + ,` | Comma selection through windows forward/backward; release `mainMod` to accept |
| `mainMod + A + ,` | Comma selection through instances of the focused app |
| `mainMod + G` / `mainMod + Shift + G` | Comma selection through workspaces forward/backward |
| `mainMod + Y` / `mainMod + Shift + Y` | Comma selection through Play/Pause, Next and Previous |
| `mainMod + H` | Switch between workspaces 1 and 2 |
| `mainMod + M` | Focus the next layout window |
| `mainMod + N` | Rotate window positions while retaining the focused slot |
| `mainMod + W` | Close the focused window |
| `mainMod + R` | Toggle the Rofi application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |

## Dot mode

Press `mainMod + .`; the top-right `dot mode` notice remains visible until the
next key ends the mode. The macOS implementation uses native `hs.chooser` surfaces
instead of Rofi.

| Key | Action |
| --- | --- |
| `Q` | Capture a region |
| `A` | Capture the focused window |
| `Z` | Capture the focused monitor |
| `B` | Select a connected display; toggling requires an additional supported display-control tool |
| `G` | Toggle a project Neovim overlay |
| `Shift + G` | Toggle a project Lazygit overlay |
| `J` | Toggle a project Kitty overlay |
| `E` | Select and insert an emoji |
| `R` | Select a configured command |
| `T` | Select and insert a snippet |
| `Escape` | Leave dot mode |

macOS additionally keeps `H/L`, `Shift + H/L` and `/` in Dot Mode for moving the
focused/all visible windows between displays and toggling AeroSpace fullscreen.
Project identity is taken from path-based VS Code titles such as
`~/dotfiles | Code`; non-path titles are deliberately rejected.

Project overlays use the absolute project path from the active VS Code title and
reuse one floating Kitty window per project and tool. Changing the workspace hides
the visible overlay.

## Application shortcut forwarding

`Ctrl + P/H/J/K/L` reaches the focused application unchanged. In Chrome it maps
to `Ctrl+Shift+A`, `Alt+Left`, `Ctrl+Shift+Tab`, `Ctrl+Tab` and `Alt+Right`.

Media, volume, microphone and brightness hardware keys use their native actions.
The read-only shortcut catalogs use `Shortcut — Description` rows and include
global bindings, modifier combinations, Dot mode and hardware/media bindings.
Hyprland's Lua entry point is `home/.config/hypr/hyprland.lua`; architecture and
desktop integration notes live in [`docs/hyprland-lua.md`](docs/hyprland-lua.md)
and [`docs/hyprland-desktop.md`](docs/hyprland-desktop.md). The active macOS
responsibility split is documented in
[`docs/macos-window-management.md`](docs/macos-window-management.md). Explicitly
postponed fixes and refactorings are tracked in
[`docs/deferred-work.md`](docs/deferred-work.md).
