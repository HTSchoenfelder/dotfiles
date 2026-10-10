# Hyprland Lua architecture

`home/.config/hypr/hyprland.lua` loads the host monitor configuration, environment,
input, appearance, session startup and keybindings. Files under `config/` describe
the setup; files under `lib/` implement reusable behavior.

## Cross-platform interaction model

Hyprland is the reference implementation for the interaction design in this
repository. Its navigation, application keys, held modifiers, Comma Selection and
Dot Mode define the muscle memory that the macOS Hammerspoon configuration should
reproduce wherever macOS exposes a reliable equivalent.

Parity is measured by what a shortcut means and how the interaction feels, rather
than by matching compositor internals. On macOS, Hammerspoon reproduces the input,
selection and master/stack model directly through Accessibility. It deliberately
does not reproduce Hyprland workspaces or Parking.
Platform-specific implementation details are acceptable when the keys, sequence
and visible outcome remain aligned. Any deliberate behavioral difference that
affects muscle memory should be recorded in the relevant quick reference or in the
[macOS window-management architecture](macos-window-management.md). Application
shortcut and text-input differences are tracked separately in
[macOS keyboard parity](macos-keyboard-parity.md).

Hyprland uses at most two normal tiled windows per displayed workspace. App keys,
instance selection, `P` and Comma Selection replace the focused slot. Shift app
and `P` selection target the other slot and retain the focused side; they expand
one slot into two only when a distinct selected window becomes available. Shift
in Comma Selection remains backward cycling. `F` selects an instance or filters
Comma Selection by application.

Selection from Parking or a hidden workspace parks the displaced occupant.
Selection from another visible slot exchanges both occupants through the native
window-swap dispatcher. `M` switches occupied slots, `N` swaps their contents
without changing the focused side, and `H` focuses the other display's visible
workspace. `H` is a no-op with one enabled monitor. There is no held `G` modifier;
Dot Mode project-tool bindings retain their independent meanings.

`/` explicitly reduces the layout to the focused window. `Shift + /` requests
two slots and refills the other side from Parking MRU; without a candidate, the
vacancy remains remembered for the next normal window. Dot Mode `M` toggles
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

macOS currently retains application/`P` layout replacement and Shift-to-stack,
plus its existing comma slot adoption. It does not yet implement the two-slot cap,
Parking refill or Dot Mode ratio toggle. See the documented platform differences.

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
| `lib/shortcut_catalog.lua` | Read-only searchable catalog of global, Dot mode and hardware shortcuts |
| `lib/shortcut_forwarding.lua` | Native shortcut delivery to the focused application |
| `lib/dot_mode.lua` | Dot mode lifecycle and persistent native notification |
| `lib/monitor_configuration.lua` | Host monitor rules and Rofi display toggling |
| `lib/project_overlays.lua` | Project discovery and reusable floating Kitty overlays |
| `lib/launcher_data.lua` | Shared launcher file loading and validation |
| `lib/command_launcher.lua` | Configured command parsing and execution after selection |
| `lib/text_launcher.lua` | Emoji/snippet parsing and insertion into the original window |
| `lib/media_controls.lua` | Three-action player menu and Spotify MPRIS commands |
| `lib/screenshots.lua` | Hyprshot region, active-window and active-output commands |
| `lib/process.lua` | Quoted argument vectors and asynchronous process startup |
| `lib/compositor.lua` | Checked dispatch, current workspace and shared selection indexing |

The master layout starts at 70:30 and supports a per-display 50:50 toggle.
macOS retains its 1:1 split. Hyprland parks replaced slot occupants; macOS leaves
unrelated windows unchanged behind its managed layout. Workspace cycling remains
Hyprland-only.

Focus and window transitions are intentionally restrained. Focus opacity and border
changes complete in 100 ms, window movement in 150 ms and window open/close motion
uses a short non-overshooting curve. Border-angle interpolation is disabled, while
workspace transitions retain their separate timing.

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
monitor. `M` toggles the active display split. `B` selects and toggles connected
displays. `G`, `Shift+G` and `J` toggle project LazyVim, Lazygit and terminal
overlays. `E`, `R` and `T` select emojis,
configured commands and snippets. The submap resets before the selected tool opens.
`mainMod + R` still opens the application launcher. `mainMod + Shift + R` opens
the read-only shortcut catalog through the same Rofi picker infrastructure.

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
The scenarios cover slot replacement and cross-display swaps, Shift targeting,
close/refill focus and ordering, exhausted Parking, session-state restoration,
monitor MRU and empty/single displays, workspace changes and launch races,
cycling, cancellation, reload, the shortcut catalog, player actions, shortcut
forwarding, command selection, monitor toggling, project overlays and text
insertion.
Validate configuration/API calls with the installed Hyprland's `--verify-config`.
Use a running session for Rofi's real keyboard and layer lifecycle; Lua mocks do
not prove compositor event ordering or Wayland input behavior.
