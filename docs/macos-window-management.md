# macOS window-management architecture

## Status

This document describes the active architecture. Hammerspoon owns interaction and
AeroSpace 0.21+ owns managed window state and geometry. The repository-managed
`home/.aerospace.toml` is a backend-only policy with no workflow bindings, and the
official AeroSpace Homebrew cask is declared in `setup/macos/Brewfile`.

The completed implementation brief is
[`aerospace-migration.md`](../aerospace-migration.md). It is intentionally
self-contained and remains the acceptance record for the migration.

Hyprland remains the behavioral source of truth. The macOS implementation should
preserve shortcut shapes, held modifiers, navigation semantics and selection
lifecycle wherever macOS exposes reliable behavior.

## Responsibility boundaries

| Component | Responsibility |
| --- | --- |
| Hyprland | Reference interaction model and shortcut semantics |
| Hammerspoon | All global shortcuts, modifier/key-release state, Comma Selection, Dot Mode, chooser UI, application intentions, MIDI/hardware integration and master-layout orchestration |
| AeroSpace | Window tree, tiling geometry, workspace state, monitor assignment, focus, move, swap and resize operations |

Hammerspoon is the only keyboard-input owner. AeroSpace does not need regular
keybindings and should not duplicate Hammerspoon shortcuts. A Hammerspoon action
invokes the `aerospace` CLI asynchronously; the CLI talks to the already-running
AeroSpace process through its socket protocol.

```text
keyboard
   |
   v
Hammerspoon hotkey and mode handling
   |
   v
AeroSpace CLI and socket
   |
   v
AeroSpace window tree
```

Hammerspoon is not a second source of managed window geometry.
It decides the intended operation and asks AeroSpace to execute it. Current window,
workspace and monitor state should be queried from AeroSpace instead of maintained
as a competing long-lived model in Lua.

## Configuration model

AeroSpace is configured declaratively with `aerospace.toml`; it does not provide a
Lua configuration API. The TOML file owns stable window rules, normalization,
default layouts, gaps, workspace-to-monitor assignments and lifecycle callbacks.
It may be installed and linked declaratively by the macOS setup without generating
TOML from Lua.

Homebrew owns the AeroSpace application and CLI because it is the upstream
recommended installation path and already owns macOS GUI applications in this
repository. Nix must not install a second AeroSpace package. The TOML remains
repository-managed independently of the package source.

`setup/macos/setup-macos.sh` applies `setup/macos/Brewfile` and passes its selected
configuration consistently to the `nix-darwin` flake. Homebrew is the sole
AeroSpace package owner.

Dynamic interaction remains Lua because it belongs to Hammerspoon. Hammerspoon
uses `hs.task` to invoke explicit AeroSpace commands such as `focus`, `swap`,
`move-node-to-workspace`, `join-with` and `balance-sizes`. Multi-step mutations
should use one `aerospace eval` call where possible so ordering stays inside
AeroSpace and the interaction requires only one client/socket round trip.

## Master and stack representation

AeroSpace has an i3-style tree and no native master-layout role. It can represent
the required visual structure with nested tile containers:

```text
h_tiles
|- master window
`- v_tiles
   |- stack window 1
   `- stack window 2
```

One window naturally occupies the available area. Two windows use an `h_tiles`
root and balanced sizes for a 1:1 split. For three windows, `join-with` creates the
vertical stack on the right.

This ratio is a deliberate platform difference: the current Hyprland master uses
70% for the master and 30% for the stack, while the requested macOS layout is 1:1.
The navigation keys, Parking behavior and master/right-stack semantics stay the
same.

Hammerspoon supplies the missing semantics: it decides which window is master,
where a selected application belongs and when the expected tree needs to be
restored after a high-level navigation action. AeroSpace remains responsible for
the resulting geometry and tree mutations.

## Interaction performance

This split is suitable for interactive use when the boundary stays coarse:

- Hotkeys, held modifiers, key-up acceptance and chooser state remain inside the
  long-running Hammerspoon process.
- Each completed navigation action should produce one asynchronous AeroSpace CLI
  request rather than several blocking shell calls.
- Comma Selection should query candidate windows once when it opens, cycle locally
  in Hammerspoon and send only the accepted focus or move operation to AeroSpace.
- Repeated keys should reuse known selection state and coalesce or reject stale
  asynchronous results instead of launching overlapping state queries.
- Explicit window IDs should be passed whenever an action was derived from a
  chooser, preventing focus changes during the request from changing its target.

The CLI process adds a small launch and socket cost, while actual window operations
still depend on macOS Accessibility responses from the target application. That
boundary is appropriate for discrete keyboard actions. Blocking process I/O in a
hotkey callback or querying the complete window list for every repeat event would
make the interaction feel slower and must be avoided.

## Launcher and hardware integration

`hs.chooser` is the shared native selection surface for applications, windows,
instances, Spotify actions, emoji, snippets, commands and the shortcut catalog.
It also supports Comma Selection because Hammerspoon can track the selected row
and accept it on modifier release. Media Comma Selection invokes Spotify through
an asynchronous `osascript` task after the highlighted action is accepted.

RØDECaster handling stays in Hammerspoon. `hs.midi` owns MIDI input/output,
device lifecycle and feedback overlays; AeroSpace has no MIDI responsibility.

## Implemented modules

- `modules/aerospace_client.lua` is the only raw CLI/task boundary and retains all
  active `hs.task` objects.
- `modules/window_repository.lua` joins AeroSpace records with Accessibility
  windows; `modules/window_history.lua` owns MRU metadata.
- `modules/layout_planner.lua` and `modules/layout_orchestrator.lua` translate
  Parking and master/stack intentions into ordered AeroSpace expressions.
- Application, window and workspace navigation keep independent high-level logic
  and share the compact chooser lifecycle.
- `modules/media_controls.lua` applies the same chooser lifecycle to Spotify's
  Play/Pause, Next and Previous actions without blocking Hammerspoon.
- Dot Mode owns screenshots, trusted text/command launchers and project overlays;
  managed window mutations still go through AeroSpace.

## Platform limits

AeroSpace and supported macOS APIs cannot enable or disable physical displays.
Dot Mode can enumerate connected enabled displays, but selecting one reports that
no supported toggle API is available. Adding a third-party display-control utility
requires a separate package and trust decision.

VS Code project overlays require a path-bearing title such as
`~/dotfiles | Code`. This signal is present on the target Mac. Titles that expose
only a folder name are rejected instead of guessing a project directory. Lazygit
is declared in the macOS Nix package set and becomes available after the next
normal configuration activation.
