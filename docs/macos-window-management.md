# macOS window-management architecture

## Status

Hammerspoon is the only macOS workflow and window-management process. It owns
global input, application intentions, MRU history, chooser state and passive
master/stack geometry. It uses the supported macOS Accessibility window API
exposed by `hs.window`; AeroSpace, Stage Manager, Mission Control and native Spaces
are not workflow backends.

Hyprland remains the behavioral reference. Shortcut shape, selection lifecycle and
master/stack intent stay aligned where macOS has a reliable equivalent. macOS does
not emulate Hyprland workspaces or Parking.

## Responsibility boundaries

| Component | Responsibility |
| --- | --- |
| Hyprland | Reference interaction model and shortcut semantics |
| Hammerspoon | Global shortcuts, held-key state, Comma Selection, Dot Mode, chooser UI, application launch/focus, MRU state, MIDI, explicit window geometry and layout-slot frames |
| macOS Accessibility | Native window discovery, focus, close, minimize, restore, frame and display association |
| JankyBorders | Optional two-state alternative for global window borders; never layout or navigation |

Hammerspoon changes frames only in direct response to a shortcut. It does not run
a permanent reflow loop, create virtual workspaces, hide unrelated applications or
maintain a competing model of every window on the desktop.

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

Hammerspoon retains a compact layout record per display:

```text
display ID -> { screen, focused slot, slots [{ window ID, frame }] }
```

The slot frames are the stable visual layout. Window IDs identify the current
occupants:

```text
master window | stack window 1
              | stack window 2
```

One selected window fills the usable display frame. Two windows use a balanced
left/right split. Three or more retain the left master and divide the right half
equally between stack windows. `config.navigation.gap` controls both outer and
inner spacing; zero restores edge-to-edge geometry.

Normal application activation replaces the tracked layout with the selected
full-size window. Other macOS windows remain unchanged behind it. This is the
deliberate replacement for Hyprland Parking: no unrelated window is minimized,
hidden or moved. `Shift + App` and `Shift + P` preserve the current layout and
append the selected window to its stack. After external focus has reset a layout,
the next Shift action uses that focused window as the new master.

`MainMod + /` explicitly reduces the current display's tracked layout to the
focused window. `MainMod + G + /` moves that window to the next display and
replaces its tracked layout; `MainMod + G + H` moves it there and appends it to the
existing tracked layout. Windows removed from a layout retain their native frame
and remain behind the new layout rather than being minimized or hidden.

Native actions outside this model invalidate the affected display's layout. This
includes focusing an untracked window, manually moving a tracked window, closing,
minimizing or hiding it, and changing the display configuration. The slot frames
then disappear instead of trying to infer or repair an externally changed layout.

`M` focuses the next tracked layout window. `N` rotates window identities through
the existing visual slots and focuses the window that arrives at the previously
focused slot. `H` adopts the most recently used visible window on the next display
into that display's focused slot, or creates a single-window layout there.
Workspace cycling has no macOS binding.

## Selection and modifiers

`F` is the application filter:

- `MainMod + F + App` always opens the instance chooser.
- `MainMod + F + ,` limits Comma Selection to the focused application.

`G` is a held destination modifier for window placement. It changes the target
from the current display to the next spatially ordered display. Comma Selection
never moves a window between displays.

Shift has two independent, unambiguous roles:

- with an application key or `P`, it adds the selected window to the layout;
- with Comma Selection or media selection, it retains the existing backward
  direction.

Comma Selection queries native windows once, cycles locally and accepts the
highlighted window when the base MainMod keys are released. A window already in a
layout is focused in its existing slot. An untracked window replaces the focused
slot on its own display while preserving that slot's frame; without an existing
layout on that display it creates a single-window layout. This is a controlled
layout action, but never a cross-display move. Window and application choices are
ordered by Hammerspoon's focus history.

## Application and overlay lifecycle

Application launch uses asynchronous `/usr/bin/open -g` tasks so a pending launch
does not intentionally steal focus. A request generation prevents a late result
from applying an obsolete layout intention. Existing hidden or minimized target
windows are focused immediately and receive a short restoration delay before
their Accessibility frame is changed. Already visible windows use a synchronous
focus path with no timer. Application shortcuts query only the target
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
Spotify actions run asynchronously through `osascript`.

RØDECaster MIDI remains entirely in Hammerspoon. `MainMod + Backslash` toggles its
mute state; hardware callbacks and feedback overlays remain independent of window
management.

## Implemented modules

- `modules/window_repository.lua` exposes usable native windows and joins them with
  Hammerspoon MRU metadata.
- `modules/layout_planner.lua` calculates full, split and master/stack frames.
- `modules/layout_orchestrator.lua` exclusively owns the per-display slot records,
  applies explicit Accessibility operations and invalidates layouts after external
  native changes. It publishes read-only snapshots to visual consumers.
- `modules/layout_observer.lua` debounces native window and display events and
  reports them to the orchestrator without owning or mutating layout state.
- `modules/layout_borders.lua` renders event-driven Catppuccin slot frames without
  participating in layout decisions.
- Application and window navigation share the compact chooser and request gate.
- `modules/media_controls.lua` applies the same selection lifecycle to Spotify.
- Dot Mode owns screenshots, text launchers and minimized project overlays.

## Platform differences

- Hyprland has Terminal, Display and Parking workspaces; macOS has no workflow
  workspaces. Hyprland cycles them with `MainMod + B`.
- Hyprland uses a 70/30 master ratio; macOS uses a 1:1 left/right ratio.
- Hyprland Dot Mode can toggle physical displays. macOS Accessibility cannot, so
  Dot Mode has no `B` action.
- macOS has no extra Dot Mode window movement or fullscreen actions.
- Hyprland Comma Selection brings a chosen window into the current workspace;
  macOS adopts it into a slot on the window's existing display.

VS Code project overlays require a path-bearing title such as
`~/dotfiles | Code`. Non-path titles are rejected rather than guessed.
