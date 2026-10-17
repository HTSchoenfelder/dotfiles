# Hyprland Lua architecture

`home/.config/hypr/hyprland.lua` loads the host monitor configuration, environment,
input, appearance and keybindings. Files under `config/` describe
the setup; files under `lib/` implement reusable behavior.

## Cross-platform interaction model

Hyprland is the reference implementation for the interaction design in this
repository. Its navigation, application keys, held modifiers, Comma Selection and
Dot Mode define the muscle memory that the macOS Hammerspoon configuration should
reproduce wherever macOS exposes a reliable equivalent.

Parity is measured by what a shortcut means and how the interaction feels, rather
than by matching compositor internals. On macOS, Hammerspoon reproduces the input,
selection and two-slot model directly through Accessibility. It deliberately
does not reproduce Hyprland workspaces or Parking.
Platform-specific implementation details are acceptable when the keys, sequence
and visible outcome remain aligned. Any deliberate behavioral difference that
affects muscle memory should be recorded in the relevant quick reference or in the
[macOS window-management architecture](macos-window-management.md). Application
shortcut and text-input differences are tracked separately in
[macOS keyboard parity](macos-keyboard-parity.md).

Hyprland uses at most two normal tiled windows per displayed workspace. App keys,
instance selection, `P` and Comma Selection replace the focused slot. Held `F`
filters by application or requests an explicit instance, while held `S` targets
the other slot and retains the focused side. `F + S` composes both meanings.
Within Comma Selection, Shift only reverses direction, including filtered or
other-slot selection. An `S` selection expands one slot into two only when a
distinct window becomes available.

Selection from Parking or a hidden workspace parks the displaced occupant.
Selection from another visible slot exchanges both occupants through the native
window-swap dispatcher. `M` switches occupied slots, `N` swaps their contents
without changing the focused side, and `H` focuses the other display's visible
workspace. `H` is a no-op with one enabled monitor. There is no held `G` modifier;
Dot Mode project-tool bindings retain their independent meanings.

`/` explicitly reduces the layout to the focused window. `Shift + /` requests
two slots and refills the other side from Parking MRU; without a candidate, the
vacancy remains remembered for the next normal window. Dot Mode `/` toggles
70:30 and 50:50, with the master always on the left and the ratio remembered per
display. The existing workspace reset explicitly places the terminal as the only
slot in workspace 1.

### Slot lifecycle

`lib/slot_layout.lua` owns slot identity, desired slot count, focused side and
per-display split preferences. Hyprland owns native window lifetime and master
geometry. Window events trigger discrete placement/refill operations; there is no
polling or permanent geometry/reflow loop. No third-party window manager, service
or placeholder window is introduced.

`window.open_early` snapshots the intended slot before native focus changes.
Placement waits until after `window.open`. Explicit launch requests take priority;
requests invalidated by newer selection, slot revision or focus changes park late
results instead of replacing current work. Unsolicited normal windows fill a
remembered vacancy or replace their original focused slot. Floating utility
windows/dialogs, hidden group members, special workspaces and project overlays
are excluded from slot selection and refill.

`window.close` records the vacated side and focus before native teardown. A
one-shot callback refills from Parking MRU after teardown, preserving the peer
and background keyboard focus. If no candidate exists, desired slots and their
identities remain recorded while native master tiling temporarily enlarges the
remaining window. Explicit `/` sets the desired count to one, so its parked
occupant is not immediately restored. Vacancies can be filled after later opens
or explicit selection places new candidates in Parking.

Session state is saved as data-only TSV under `XDG_RUNTIME_DIR`, keyed by the
compositor instance, on config unload and consumed on the next load. Only slot
addresses/counts/focused side and monitor ratios are stored, never window titles
or executable Lua. A new compositor session adopts its live windows. Existing
layouts with more than two normal windows are normalized once, preserving the
master and focused window when possible and parking excess occupants.

Workspace rules scope Terminal and Parking persistence to the configured primary
display. After an output is enabled or reconnected, a deferred role reconciliation
moves Terminal and Parking back to the primary display and Display to the
secondary display. This repair preserves the active window and slot contents; the
explicit workspace reset remains responsible for focusing Terminal and reducing
it to one slot.

macOS uses the same `F` filter, `S` target and Shift direction axes, two-slot model,
cross-display swaps and ratios. Its native non-slot windows replace Parking as
refill candidates; an empty display is selected through Hammerspoon's retained
active-frame state. Dot Mode still uses `M` for the ratio on macOS.

| File | Responsibility |
| --- | --- |
| `config/application_shortcuts.lua` | Ctrl shortcuts and application-specific mappings |
| `config/navigation.lua` | Modifier, application commands/classes and navigation preferences |
| `config/project_overlays.lua` | Project overlay tools and hidden workspace |
| `config/workspaces.lua` | Master layout, workspace icons and Parking destination |
| `config/keybindings.lua` | Bindings and composition of navigation/launcher actions |
| `config/hardware_keys.lua` | Volume, microphone, brightness and playback keys |
| `config/window_rules.lua` | Maximize suppression and XWayland drag focus correction |
| `lib/window_navigation.lua` | MRU selection, captured slot intentions and asynchronous application startup |
| `lib/slot_layout.lua` | Two-slot placement, cross-display swaps, close/refill lifecycle and session state |
| `lib/workspace_navigation.lua` | Workspace MRU history and workspace selection |
| `lib/rofi_picker.lua` | One active selection, native cycling/release bindings, cancellation and cleanup |
| `lib/rofi_mode.lua` | Standalone Rofi script provider and numeric selection replies |
| `lib/shortcut_catalog.lua` | Searchable, actionable catalog of global, Dot mode and hardware shortcuts |
| `lib/shortcut_forwarding.lua` | Native shortcut delivery to the focused application |
| `lib/dot_mode.lua` | Dot mode lifecycle and persistent native notification |
| `lib/monitor_configuration.lua` | Host monitor rules, Rofi display toggling and deferred workspace-role repair |
| `lib/project_overlays.lua` | Project discovery and reusable floating Kitty overlays |
| `lib/launcher_data.lua` | Shared launcher file loading and validation |
| `lib/command_launcher.lua` | Configured command parsing and execution after selection |
| `lib/text_launcher.lua` | Emoji/snippet parsing and insertion into the original window |
| `lib/media_controls.lua` | Three-action player menu and Spotify MPRIS commands |
| `lib/screenshots.lua` | Hyprshot region, active-window and active-output commands |
| `lib/process.lua` | Quoted argument vectors and asynchronous process startup |
| `lib/compositor.lua` | Checked dispatch, current workspace and shared selection indexing |

The master layout starts at 70:30 and supports a per-display 50:50 toggle.
macOS uses the same 70:30/50:50 ratios. Hyprland parks replaced slot occupants;
macOS leaves them as native non-slot windows. Workspace cycling remains
Hyprland-only.

Focus and window transitions are intentionally restrained. Focus opacity and border
changes complete in 100 ms, window movement in 150 ms and window open/close motion
uses a short non-overshooting curve. Border-angle interpolation is disabled, while
workspace transitions retain their separate timing.

Normal active borders retain the Catppuccin Mocha Green–Sky–Mauve gradient.
Focused project overlays override it with solid Catppuccin Mocha Sky; hidden
overlays need no inactive override.

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
the mode ends. A no-op press binding consumes the selected key before its release
binding runs the action, so a focus-changing action cannot leak either event into
the old or newly focused client. `Q`, `A` and `Z`
capture a region, the active window and the active
monitor. `/` toggles the active display split. `B` selects and toggles connected
displays. `V`, `G` and `J` toggle project Neovim, Lazygit and terminal overlays;
`W` hides all project overlays. `E` and `T` select emojis and snippets. The submap
resets before the selected tool opens.
Neovim receives the project directory as `.` in addition to inheriting it as its
working directory, so the overlay opens the project rather than an empty dashboard.
`mainMod + R` still opens the application launcher. `mainMod + Shift + P` opens
the actionable shortcut catalog through the same Rofi picker infrastructure,
matching the command-palette shape. `mainMod + Shift + R` selects configured
commands directly instead of routing them through Dot Mode.
Rows show their description first and a right-aligned shortcut; accepting a row
runs its action after Rofi has closed and keyboard focus has returned.

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
or moving session daemons into the compositor. Current portal, toolkit and user
service ownership is declared in `setup/nixos/desktop-integration.nix` and
`setup/nixos/desktop-session.nix`. Waybar, Hyprpaper and Hypridle are wanted by
`hyprland-session.target`, while general desktop helpers are wanted by
`graphical-session.target`. `systemd --user` owns supervision for both groups;
Hyprland Lua does not launch long-running session daemons directly.

## Validation

Run `lua tests/hyprland_test.lua` from the repository root for behavioral checks.
The scenarios cover slot replacement and cross-display swaps, Shift targeting,
close/refill focus and ordering, exhausted Parking, session-state restoration,
monitor MRU and empty/single displays, workspace changes and launch races,
cycling, cancellation, reload, the shortcut catalog, player actions, shortcut
forwarding, command selection, monitor toggling, project overlays and text
insertion.
Validate configuration/API calls with the installed Hyprland's `--verify-config`.
Use a running session for Rofi's real keyboard and layer lifecycle; Lua mocks do
not prove compositor event ordering or Wayland input behavior.
