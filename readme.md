# Dotfiles

Personal NixOS, Hyprland and macOS configuration for Henrik's desktop workflow.

## Workflow goal

Hyprland is the reference environment for building Henrik's keyboard-driven
workflow. The macOS configuration reproduces that interaction model through
Hammerspoon and native Accessibility so the same muscle memory applies on both
systems. Shortcut shapes, modifier combinations, navigation semantics and
selection flows should remain aligned.

Reliable platform-native behavior takes precedence when exact parity would be
fragile. Intentional differences that affect muscle memory must stay explicit and
documented.

Hammerspoon is the only macOS workflow process. It owns shortcuts, modes, choosers,
application intentions, MRU state, MIDI integration and passive master/stack
geometry through native windows. It changes frames only for explicit actions and
does not use AeroSpace, Stage Manager, Mission Control or Spaces. See the
[macOS window-management architecture](docs/macos-window-management.md).

The interaction model is shared, while the requested split ratio intentionally
differs: Hyprland currently uses a 70/30 master/stack split and the macOS target
uses 1:1.

## macOS / Hammerspoon quick reference

`mainMod` = `Option + Control + Command`. Application shortcuts use bundle IDs and
the Hammerspoon MRU history. Normal activation fills the active display with the
selected window and leaves unrelated windows unchanged behind it. Holding `Shift`
keeps the current layout and adds the selected window to the right stack. Holding
`F` opens the instance chooser, including for a single instance.

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/I/;/O/U` | Activate Kitty / VS Code / Chrome / Google Chat / Obsidian / KeePassXC / Spotify as the full-size layout |
| `mainMod + Shift + app key` | Add the selected application to the right stack |
| `mainMod + F + app key` | Select an application window before placing it |
| `mainMod + P` / `mainMod + Shift + P` | Select any window by recent focus; replace the layout / add it to the stack |
| `mainMod + ,` / `mainMod + Shift + ,` | Focus windows forward/backward by MRU without changing their layout; release `mainMod` to accept |
| `mainMod + F + ,` | Focus windows of the current application without changing their layout |
| `mainMod + Y` / `mainMod + Shift + Y` | Cycle through Spotify Play/Pause, Next and Previous; release `mainMod` to accept |
| `mainMod + M` | Focus the next window in the active layout |
| `mainMod + N` | Rotate positions while retaining focus on the visual slot |
| `mainMod + H` | Focus the most recent window on the other display |
| `mainMod + /` | Keep only the focused window in the current display layout |
| `mainMod + G + /` | Move the focused window to the next display and replace its layout |
| `mainMod + G + H` | Move the focused window to the next display and add it to its layout |
| `mainMod + W` | Close the focused window |
| `mainMod + R` | Toggle the native application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |
| `mainMod + Backslash` | Toggle the RØDECaster mute state |

Application, window and comma selection use the same compact `hs.chooser`
presentation. The application launcher lists top-level bundles from the standard
application directories with their native icons. macOS has no workflow workspaces
or Parking state.

Managed layouts use one full-size window, a 1:1 left/right split for two windows,
and a left master with a vertical right stack for three or more windows.

## Hyprland quick reference

`mainMod` = `Super + Ctrl + Alt`. Application navigation reuses the most recently
focused matching window or starts the app. Other windows on the active workspace
move to Parking (`󰮍`). Hold `Shift` to keep them and place the target in the
master stack. Hold `F` to choose an existing instance.

| Shortcut | Action |
| --- | --- |
| `mainMod + J` | Kitty with Zellij |
| `mainMod + K` | VS Code |
| `mainMod + L` | Chrome |
| `mainMod + I` | Google Chat |
| `mainMod + ;` | Obsidian |
| `mainMod + O` | KeePassXC |
| `mainMod + U` | Spotify |
| `mainMod + Shift + app key` | Keep the current layout and add the selected app to its stack |
| `mainMod + F + app key` | Select an application instance |
| `mainMod + P` / `mainMod + Shift + P` | Select any window / select and add it to the stack |
| `mainMod + ,` / `mainMod + Shift + ,` | Comma selection through windows forward/backward; release `mainMod` to accept |
| `mainMod + F + ,` | Comma selection through instances of the focused app |
| `mainMod + B` / `mainMod + Shift + B` | Comma selection through workspaces forward/backward |
| `mainMod + Y` / `mainMod + Shift + Y` | Comma selection through Play/Pause, Next and Previous |
| `mainMod + H` | Switch between workspaces 1 and 2 |
| `mainMod + /` | Keep only the focused window in the current workspace layout |
| `mainMod + G + /` | Move the focused window to the next display and replace its active workspace layout |
| `mainMod + G + H` | Move the focused window to the next display and add it to its active workspace layout |
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
| `B` | Toggle a connected display (Hyprland only) |
| `G` | Toggle a project Neovim overlay |
| `Shift + G` | Toggle a project Lazygit overlay |
| `J` | Toggle a project Kitty overlay |
| `E` | Select and insert an emoji |
| `R` | Select a configured command (Hyprland) / reset the current window layout (macOS) |
| `T` | Select and insert a snippet |
| `Escape` | Leave dot mode |

On macOS, project identity is taken from path-based VS Code titles such as
`~/dotfiles | Code`; non-path titles are deliberately rejected.

Project overlays use the absolute project path from the active VS Code title and
reuse one Kitty window per project and tool. Toggling an overlay off minimizes
that window; opening another overlay minimizes the previous one.

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
