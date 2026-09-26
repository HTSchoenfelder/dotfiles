# Dotfiles

Personal NixOS, Hyprland and macOS configuration for Henrik's desktop workflow.

## macOS / Hammerspoon quick reference

`mainMod` = `Option + Control + Command`. Application shortcuts bring the
application's main window to the front and place it on demand. Hammerspoon does
not track window slots, reflow displays or minimize other windows. Window lists
and display focus targets are resolved only when their shortcut is pressed.

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/;/O/U` | Focus Kitty / VS Code / Chrome / Obsidian / KeePassXC / Spotify on the primary display |
| `mainMod + F + app key` | Fill the secondary display |
| `mainMod + Z + app key` | Use the left half of the secondary display |
| `mainMod + X + app key` | Use the right half of the secondary display |
| `mainMod + C + app key` | Use the left half of the primary display |
| `mainMod + V + app key` | Use the right half of the primary display |
| `mainMod + A + app key` | Select an application window before placing it |
| `mainMod + P` | Select any window |
| `mainMod + ,` / `mainMod + Shift + ,` | Cycle windows forward/backward; release `mainMod` to accept |
| `mainMod + A + ,` | Cycle through windows of the focused application |
| `mainMod + M` | Focus the next window on the current display |
| `mainMod + N` | Swap the focused and frontmost other window |
| `mainMod + H` | Focus the frontmost window on the other display |
| `mainMod + W` | Close the focused window |
| `mainMod + R` | Toggle the Seal application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |
| `mainMod + Shift + M` | Toggle the RØDECaster mute state |

The placement key is held while pressing the application key, for example
`mainMod + Z + J` for Kitty on the left half of the secondary display. If no
secondary display is connected, secondary-display actions fall back to the
primary display. The implementation does not require AeroSpace or manipulate
Mission Control Spaces.

`mainMod + .` opens the existing window action mode. Its bindings and all other
macOS bindings are included in the read-only shortcut catalog.

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
| `mainMod + ;` | Obsidian |
| `mainMod + O` | KeePassXC |
| `mainMod + U` | Spotify |
| `mainMod + P` | Select any window by recent focus |
| `mainMod + ,` / `mainMod + Shift + ,` | Comma selection through windows forward/backward; release `mainMod` to accept |
| `mainMod + A + ,` | Comma selection through instances of the focused app |
| `mainMod + G` / `mainMod + Shift + G` | Comma selection through workspaces forward/backward |
| `mainMod + Y` / `mainMod + Shift + Y` | Comma selection through Play/Pause, Next, Previous and Spotify |
| `mainMod + H` | Switch between workspaces 1 and 2 |
| `mainMod + M` | Focus the next layout window |
| `mainMod + N` | Rotate window positions while retaining the focused slot |
| `mainMod + W` | Close the focused window |
| `mainMod + R` | Toggle the Rofi application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |

`F` and `A` can be combined for application navigation and comma selection.

## Dot mode

Press `mainMod + .`; the top-right `dot mode` notice remains visible until the
next key ends the mode.

| Key | Action |
| --- | --- |
| `Q` | Capture a region |
| `A` | Capture the focused window |
| `Z` | Capture the focused monitor |
| `B` | Select a connected display in Rofi and toggle enabled/disabled |
| `G` | Toggle a project LazyVim overlay |
| `Shift + G` | Toggle a project Lazygit overlay |
| `J` | Toggle a project Kitty overlay |
| `E` | Select and insert an emoji with Rofi |
| `R` | Select a configured command with Rofi |
| `T` | Select and insert a snippet with Rofi |
| `Escape` | Leave dot mode |

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
and [`docs/hyprland-desktop.md`](docs/hyprland-desktop.md). Explicitly postponed
fixes and refactorings are tracked in [`docs/deferred-work.md`](docs/deferred-work.md).
