# macOS window-management architecture

## Status

Hammerspoon is the only macOS workflow and window-management process. It owns
global input, application intentions, MRU history, chooser state and passive
two-slot geometry. It uses the supported macOS Accessibility window API
exposed by `hs.window`; AeroSpace, Stage Manager, Mission Control and native Spaces
are not workflow backends.

Hyprland remains the behavioral reference. Shortcut shape, selection lifecycle and
two-slot behavior stay aligned. macOS does not emulate Hyprland workspaces or
Parking; non-slot native windows form the logical refill pool.

Application shortcut and text-navigation parity is a separate input concern. Its
current ownership, incomplete coverage and target contract are documented in
[macOS keyboard parity](macos-keyboard-parity.md).
The [macOS tests](macos-tests.md) cover automated and live validation of this
workflow.

## Responsibility boundaries

| Component | Responsibility |
| --- | --- |
| Hyprland | Reference interaction model and shortcut semantics |
| Hammerspoon | Global shortcuts, held-key state, Comma Selection, Dot Mode, chooser UI, application launch/focus, MRU state, MIDI, explicit window geometry and layout-slot frames |
| macOS Accessibility | Native window discovery, focus, close, minimize, restore, frame and display association |
| JankyBorders | Optional two-state alternative for global window borders; never layout or navigation |

Hammerspoon also hosts the current GUI key-remapping event tap. VS Code keeps
context-sensitive command, Monaco, Vim and terminal ownership in its native
keybinding system; Hammerspoon only adds Accessibility-gated navigation for
native and webview text inputs. This input boundary is intentionally documented
separately from window geometry.

Hammerspoon changes frames for explicit selection, close/refill and new-window
actions. It keeps only two slot identities per display in memory, not a model of
every native window. It does not run a permanent reflow loop, create virtual
workspaces or hide unrelated applications.

The optional Catppuccin frame module draws only the retained layout slots. Its
canvases are visual and click-through; replacing the window in a slot does not
recreate or reposition that slot's frame. See the
[macOS appearance layer](macos-appearance.md) for switches, service ownership and
restore commands.

```text
keyboard
   |
   v
Hammerspoon intent and selection
   |
   v
macOS Accessibility window focus/frame operation
```

## Layout model

Hammerspoon retains per-display state in Lua memory:

```text
display ID -> { screen, desired slot count, focused side, ratio, slots [window ID?] }
active display ID -> display with the Green active-slot frame
```

Each display has at most two sides. The left side is the master. One occupied slot
fills the usable display; two use 70:30 or 50:50, with `config.navigation.gap`
controlling inner and outer spacing. If a desired side is vacant, its identity is
remembered while the remaining window fills the display. On an entirely empty
display, the active slot frame is still drawn. `H` changes the active display even
when macOS cannot move native keyboard focus there; the next app or window action
uses that retained display and side.

App keys, `P` and Comma Selection replace the focused side. Shift app and `P`
selection fill the other side, expanding one to two, without leaving focus there.
A selected window in another visible slot swaps identities; Hammerspoon places
both windows into their new display frames. An untracked selection leaves the
replaced window native and unchanged. Non-slot windows are neither hidden nor
minimized to emulate Parking.

`/` keeps one slot; `Shift + /` requests two and immediately refills the second
side from the non-slot MRU pool. Dot Mode `M` toggles the ratio per display. `M`
focuses the other occupied side; `N` swaps contents while focus remains on the
same visual side. Closing a slot window refills its side from the most recently
focused usable non-slot window. If there is no candidate, a later normal window
can fill the vacancy. Window-created and close notifications trigger discrete
updates; there is no continuous tiler.

Manual movement of a tracked window removes it from its slot. Display topology
changes clear the in-memory slot records so the next action adopts current native
windows. `clearScreen` and Dot Mode reset remain explicit layout reset actions.

## Selection and modifiers

`F` selects an application instance or filters Comma Selection by application.
Shift with Comma Selection and media selection means backward cycling, never
other-slot placement. Comma Selection queries native windows once, cycles locally
and accepts on base `MainMod` release. Its accepted window uses the captured
focused side, including across displays, and can swap with another slot occupant.
Window and application choices use Hammerspoon's focus history. Held `G` display
placement is removed; `H` selects the other display without moving its existing
windows.

## Application and overlay lifecycle

Application launch uses asynchronous `/usr/bin/open -g` tasks so a pending launch
does not intentionally steal focus. A request generation prevents a late result
from applying an obsolete layout intention. Existing hidden or minimized target
windows are restored before their Accessibility frame is changed. Already visible
windows use a synchronous focus path with no timer. Application shortcuts query only the target
application's windows instead of inventorying every desktop window. Repeating an
action skips native focus and frame calls when both already match the requested
slot, avoiding redundant Accessibility redraws.

Project overlays are ordinary Kitty windows. Toggling an overlay restores and
centres that window on the active display; toggling it off minimizes only that
window. Only one project overlay is kept visible at a time. No hidden workspace is
required.

Dot Mode stores region, window and display captures in `~/screenshots`, matching
Hyprland's `HYPRSHOT_DIR`.

## Launcher and hardware integration

`hs.chooser` is the shared native selection surface for applications, windows,
instances, Spotify actions, emoji, snippets, commands and the shortcut catalog.
The launcher places an existing application window in the captured focused slot;
new native windows are assigned from window-created events.
Spotify actions run asynchronously through `osascript`.

RØDECaster MIDI remains entirely in Hammerspoon. `MainMod + Backslash` sends one
absolute mute or unmute value; it does not emulate a momentary button press. The
physical mute control reports a press and release instead, so Hammerspoon toggles
its retained state only on the press and ignores the release. A narrowly scoped
echo guard prevents an outgoing mute command from being counted as another
physical press. The persisted overlay follows the primary display and remains an
assumed state after a Hammerspoon or device restart until the next interaction.

## Implemented modules

- `modules/window_repository.lua` exposes usable native windows and joins them with
  Hammerspoon MRU metadata.
- `modules/layout_planner.lua` calculates full and ratio-based split frames.
- `modules/layout_orchestrator.lua` exclusively owns the per-display slot records,
  applies explicit Accessibility operations and retains vacancies across close
  events. It publishes read-only snapshots to visual consumers.
- `modules/layout_observer.lua` debounces native window and display events and
  reports them to the orchestrator without owning or mutating layout state.
- `modules/layout_borders.lua` renders event-driven Catppuccin slot frames without
  participating in layout decisions.
- Application and window navigation share the compact chooser and request gate.
- `modules/media_controls.lua` applies the same selection lifecycle to Spotify.
- `modules/rodecaster.lua` owns MIDI discovery and reconnection, mute-button
  state commands, physical button events, persisted assumed state and its feedback
  overlay.
- `remapping.lua` owns the key-remapper lifecycle, while
  `modules/key_remapper.lua` contains the declarative, testable application
  shortcut and text-navigation translation layer. Its ownership and remaining
  application-specific work are described in
  [macOS keyboard parity](macos-keyboard-parity.md).
- Dot Mode owns screenshots, text launchers and minimized project overlays.

## Platform differences

- Hyprland has Terminal, Display and Parking workspaces; macOS has no workflow
  workspaces. Native non-slot windows supply refill candidates instead of Parking.
- Hyprland can focus an empty output; macOS cannot. Hammerspoon keeps a logical
  active display and paints its active slot frame so subsequent actions target it.
- Hyprland Dot Mode can toggle physical displays. macOS Accessibility cannot, so
  Dot Mode has no `B` action.
- macOS has no extra Dot Mode window movement or fullscreen actions.
- Hammerspoon state lives in Lua memory and is rebuilt after reload; Hyprland
  preserves its slot vacancies across config reloads within one compositor session.

VS Code project overlays require a path-bearing title such as
`~/dotfiles | Code`. Non-path titles are rejected rather than guessed.
