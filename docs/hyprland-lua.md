# Hyprland Lua architecture

`home/.config/hypr/hyprland.lua` loads the host monitor configuration, environment,
input, appearance, session startup and keybindings. Files under `config/` describe
the setup; files under `lib/` implement reusable behavior.

| File | Responsibility |
| --- | --- |
| `config/application_shortcuts.lua` | Ctrl shortcuts and application-specific mappings |
| `config/navigation.lua` | Modifier, application commands/classes and navigation preferences |
| `config/project_overlays.lua` | Project overlay tools and hidden workspace |
| `config/workspaces.lua` | Master layout, workspace icons and Parking destination |
| `config/keybindings.lua` | Bindings and composition of navigation/launcher actions |
| `config/hardware_keys.lua` | Volume, microphone, brightness and playback keys |
| `config/window_rules.lua` | Maximize suppression and XWayland drag focus correction |
| `lib/window_navigation.lua` | Window MRU order, Parking/stack placement and asynchronous application startup |
| `lib/workspace_navigation.lua` | Workspace MRU history and workspace selection |
| `lib/rofi_picker.lua` | One active selection, native cycling/release bindings, cancellation and cleanup |
| `lib/rofi_mode.lua` | Standalone Rofi script provider and numeric selection replies |
| `lib/shortcut_forwarding.lua` | Native shortcut delivery to the focused application |
| `lib/dot_mode.lua` | Dot mode lifecycle and persistent native notification |
| `lib/monitor_configuration.lua` | Host monitor rules and Rofi display toggling |
| `lib/project_overlays.lua` | Project discovery and reusable floating Kitty overlays |
| `lib/launcher_data.lua` | Shared launcher file loading and validation |
| `lib/command_launcher.lua` | Configured command parsing and execution after selection |
| `lib/text_launcher.lua` | Emoji/snippet parsing and insertion into the original window |
| `lib/media_controls.lua` | Fixed player menu and Spotify MPRIS commands |
| `lib/screenshots.lua` | Hyprshot region, active-window and active-output commands |
| `lib/process.lua` | Quoted argument vectors and asynchronous process startup |
| `lib/compositor.lua` | Checked dispatch, current workspace and shared selection indexing |

Rofi owns the keyboard after its layer opens. Hyprland temporarily disables the
cycle bindings so Rofi can process repeated presses, Shift and modifier releases.
A release before the layer opens confirms the initial selection directly.

The [Rofi script protocol](https://github.com/davatorium/rofi/blob/2.0.0/doc/rofi-script.5.markdown)
provides numeric row metadata independently of displayed titles. Plain-text rows
are written to a private temporary file and removed on completion, cancellation or
reload. The provider runs outside the compositor; its short `hyprctl eval` calls
report only its owning Rofi PID and the selected index. Selection actions wait
until the Rofi layer closes and keyboard focus is restored. No blocking subprocess
I/O runs in Hyprland's Lua thread.

`playerctl --player spotify` remains responsible for MPRIS, and `wtype` remains
responsible for Wayland text input. Their arguments are quoted centrally; window
titles and snippet text are never evaluated as commands. Existing Rofi styling and
launcher data are reused. Snippets retain the `text|alias` format and support
`\n`, `\t` and `\\` escapes. Both text and alias are searchable.

`mainMod + period` enters dot mode and holds a native Hyprland notification until
the mode ends. `Q`, `A` and `Z` capture a region, the active window and the active
monitor. `B` selects and toggles connected displays. `G`, `Shift+G` and `J` toggle
project LazyVim, Lazygit and terminal overlays. `E`, `R` and `T` select emojis,
configured commands and snippets. The submap resets before the selected tool opens.
`mainMod + R` still opens the application launcher.

Command entries use `command|label`, split at the last `|` to allow shell pipelines.
Only labels appear in Rofi. Numeric row selection preserves duplicate labels;
only the selected command from this trusted configuration runs via `bash -c`.
Commands retain shell expansion and quoting from the original launcher.

`Ctrl + P/H/J/K/L` are forwarded through `hl.dsp.send_shortcut` to the focused
window. Chrome maps them to `Ctrl+Shift+A`, `Alt+Left`, `Ctrl+Shift+Tab`,
`Ctrl+Tab`, and `Alt+Right`; other applications receive the original shortcut.

The former shell launchers and legacy Hyprland fragments have been retired. Lua
now owns window/application navigation, text and command selection, shortcut
forwarding, screenshots, monitor toggling and project overlays. The discarded
multi-project startup, Chrome-profile tagging and twenty-workspace workflows are
outside the current design.

System installation and session-service ownership remain separate from desktop
interaction. Replacing shell navigation does not imply replacing Nix setup scripts
or moving session daemons into the compositor.
See [desktop integration](hyprland-desktop.md) for the portal, toolkit and upstream
default configuration audit.

## Validation

Run `lua tests/hyprland_test.lua` from the repository root for behavioral checks.
The scenarios cover MRU order, workspace changes, launch races, Parking/stack
placement, cycling, cancellation, reload, player actions, shortcut forwarding,
command selection, monitor toggling, project overlays and text insertion.
Validate configuration/API calls with the installed Hyprland's `--verify-config`.
Use a running session for Rofi's real keyboard and layer lifecycle; Lua mocks do
not prove compositor event ordering or Wayland input behavior.
