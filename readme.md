# Dotfiles

Personal NixOS, Hyprland and macOS configuration for Henrik's desktop workflow.

## macOS / Hammerspoon quick reference

`mainMod` = `Option + Control + Command`. Each display acts as one working area.
One managed window fills it; two managed windows use equal left and right halves.
Application navigation minimizes the other windows on the active display. Hold
`F` to retain the focused window as the left half and hold `A` to select an
application instance. `F` and `A` can be combined.

| Shortcut | Action |
| --- | --- |
| `mainMod + J` | kitty |
| `mainMod + K` | VS Code |
| `mainMod + L` | Chrome |
| `mainMod + ;` | Obsidian |
| `mainMod + O` | KeePassXC |
| `mainMod + U` | Spotify |
| `mainMod + P` | Select any window by recent focus |
| `mainMod + ,` / `mainMod + Shift + ,` | Cycle windows forward/backward; release `mainMod` to accept |
| `mainMod + A + ,` | Cycle through windows of the focused application |
| `mainMod + M` | Focus the other visible window |
| `mainMod + N` | Swap the left and right window while retaining focus |
| `mainMod + H` | Focus the last active window on the other display |
| `mainMod + W` | Close the focused window and reflow the display |
| `mainMod + Shift + M` | Toggle the RØDECaster mute state |

The implementation uses native macOS window minimizing and Hammerspoon frame
management. It does not require AeroSpace or manipulate Mission Control Spaces.

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
Hyprland's Lua entry point is `home/.config/hypr/hyprland.lua`; architecture and
desktop integration notes live in [`docs/hyprland-lua.md`](docs/hyprland-lua.md)
and [`docs/hyprland-desktop.md`](docs/hyprland-desktop.md). Explicitly postponed
fixes and refactorings are tracked in [`docs/deferred-work.md`](docs/deferred-work.md).
