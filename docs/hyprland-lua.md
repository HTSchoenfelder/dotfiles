# Hyprland Lua architecture

`home/.config/hypr/hyprland.lua` loads the host monitor configuration, environment,
input, appearance, session startup and keybindings. Files under `config/` describe
the setup; files under `lib/` implement reusable behavior.

| File | Responsibility |
| --- | --- |
| `config/navigation.lua` | Modifier, application commands/classes and navigation preferences |
| `config/workspaces.lua` | Master layout, workspace icons and Parking destination |
| `config/keybindings.lua` | Bindings and composition of navigation/launcher actions |
| `lib/window_navigation.lua` | Window MRU order, Parking/stack placement and asynchronous application startup |
| `lib/workspace_navigation.lua` | Workspace MRU history and workspace selection |
| `lib/rofi_picker.lua` | One active selection, native cycling/release bindings, cancellation and cleanup |
| `lib/rofi_mode.lua` | Standalone Rofi script provider and numeric selection replies |
| `lib/text_launcher.lua` | Emoji/snippet parsing and insertion into the original window |
| `lib/media_controls.lua` | Fixed player menu and Spotify MPRIS commands |
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

## Remaining shell migrations

The active configuration no longer starts any `scripts/*.sh` file. Legacy scripts
and `.conf` files remain as references. They are not loaded by `hyprland.lua`.
These workflows should be selected deliberately before adding more bindings:

| Legacy scripts | Proposed Lua replacement |
| --- | --- |
| `move-current-workspace-to-monitor.sh` | Move the current workspace to the adjacent monitor through `hl.dsp.workspace.move`, preserving focus explicitly. |
| `move-workspaces-reset.sh` | Reassign existing/configured workspaces to their intended monitors; avoid creating twenty workspaces as the old loop did. |
| `send-shortcut.sh` | Match the active application class and use `hl.dsp.send_shortcut` for browser/editor navigation. |
| `launcher-execute.sh` | A Rofi action picker with explicit Lua callbacks or argument vectors instead of regular-expression lookup and `eval`. |
| `notify-player-current-track.sh` | Query Spotify metadata in an external Lua worker, then display the selected track information. Keep network/artwork fetching outside the compositor. |
| `launch-chrome.sh`, `launch-chrome-instances.sh` | Optional profile definitions with window-open/class events to identify each launched window, replacing fixed sleeps. |

Already replaced or unnecessary:

- Emoji and snippet shell launchers are replaced by `E` and `Q`.
- `launcher-focus-window.sh` is replaced by application instance pickers and `P`.
- `list-desktop-files.sh` is covered by Rofi's `drun` mode.
- `exec-reset-submap.sh` is covered by Lua callbacks and the shared picker lifecycle.
- `listen-to-events.sh` is no longer started. Its project terminal handling is
  obsolete; future compositor event handling belongs in `hl.on` callbacks.
- `focus-code-window.sh`, `launch-code-project.sh`, `show-terminal.sh` and the old
  `shortcut-set.sh` / `shortcut-execute.sh` project workflow are intentionally not
  ported.

System installation and session-service ownership remain separate from desktop
interaction. Replacing shell navigation does not imply replacing Nix setup scripts
or moving session daemons into the compositor.

## Validation

Run `lua tests/hyprland_test.lua` from the repository root for behavioral checks.
The scenarios cover MRU order, workspace changes, launch races, Parking/stack
placement, cycling, cancellation, reload, player actions and text insertion.
Validate configuration/API calls with the installed Hyprland's `--verify-config`.
Use a running session for Rofi's real keyboard and layer lifecycle; Lua mocks do
not prove compositor event ordering or Wayland input behavior.
