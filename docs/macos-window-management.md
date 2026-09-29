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
| Hammerspoon | Global shortcuts, held-key state, Comma Selection, Dot Mode, chooser UI, application launch/focus, MRU state, MIDI and explicit window geometry |
| macOS Accessibility | Native window discovery, focus, close, minimize, restore, frame and display association |

Hammerspoon changes frames only in direct response to a shortcut. It does not run
a permanent reflow loop, create virtual workspaces, hide unrelated applications or
maintain a competing model of every window on the desktop.

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

Hammerspoon retains only the ordered window IDs of the current layout on each
display:

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
append the selected window to its stack. If focus was moved manually to a window
outside the tracked layout, that focused window becomes the new master first.

`M` focuses the next tracked layout window. `N` rotates window identities through
the existing visual slots and focuses the window that arrives at the previously
focused slot. `H` focuses the most recently used visible window on the next
display. Workspace cycling has no macOS binding.

## Selection and modifiers

`F` is the application filter:

- `MainMod + F + App` always opens the instance chooser.
- `MainMod + F + ,` limits Comma Selection to the focused application.

Shift has two independent, unambiguous roles:

- with an application key or `P`, it adds the selected window to the layout;
- with Comma Selection or media selection, it retains the existing backward
  direction.

Comma Selection queries native windows once, cycles locally and accepts the
highlighted window when the base MainMod keys are released. Window and application
choices are ordered by Hammerspoon's focus history.

## Application and overlay lifecycle

Application launch uses asynchronous `/usr/bin/open -g` tasks so a pending launch
does not intentionally steal focus. A request generation prevents a late result
from applying an obsolete layout intention. Existing hidden or minimized target
windows are restored before their Accessibility frame is changed.

Project overlays are ordinary Kitty windows. Toggling an overlay restores and
centres that window on the active display; toggling it off minimizes only that
window. Only one project overlay is kept visible at a time. No hidden workspace is
required.

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
- `modules/layout_orchestrator.lua` owns the small per-display layout ID lists and
  applies explicit Accessibility operations.
- Application and window navigation share the compact chooser and request gate.
- `modules/media_controls.lua` applies the same selection lifecycle to Spotify.
- Dot Mode owns screenshots, text launchers and minimized project overlays.

## Platform differences

- Hyprland has Terminal, Display and Parking workspaces; macOS has no workflow
  workspaces and therefore no `MainMod + G` binding.
- Hyprland uses a 70/30 master ratio; macOS uses a 1:1 left/right ratio.
- Hyprland Dot Mode can toggle physical displays. macOS Accessibility cannot, so
  Dot Mode has no `B` action.
- macOS has no extra Dot Mode window movement or fullscreen actions.

VS Code project overlays require a path-bearing title such as
`~/dotfiles | Code`. Non-path titles are rejected rather than guessed.
