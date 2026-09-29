# Deferred Work

This file records fixes and refactorings that may be useful later. Entries are
documentation only. Do not implement, investigate further, or include them in
another change unless Henrik explicitly requests the specific item.

## Project editor overlay leaks `G` input

`dot mode` followed by `J` toggles the project terminal overlay reliably. With
the LazyVim overlay, the first `dot mode` + `G` opens it, but the same sequence
does not reliably hide it again. The `G` input can reach the previously focused
client instead; this was observed as two literal `g` characters in a chat input.

Adding `dont_inhibit` to the dot-mode bindings and
`no_shortcuts_inhibit = true` to the project-overlay window rule did not resolve
the behavior. A later fix should trace the real key press and release sequence,
submap transitions, focus changes, and possible event forwarding before changing
the binding model again.

## Keep configured workspaces permanent

The configured workspaces should remain available while empty. Workspace 1
(``) currently disappears after its final window leaves it, for example after
manually switching to Parking. Configure the primary and Parking workspace rules
as persistent using the current Hyprland Lua API so their names and navigation
targets remain stable.

## Add an optional macOS look-and-feel layer

Improve the visual consistency between macOS and the Hyprland setup without
replacing the existing Hammerspoon navigation. Every appearance feature must be
optional, independently configurable where practical, and reproducible from the
dotfiles. Provide an idempotent setup script plus a documented restore path for
system settings and background services.

### Focus border

Use JankyBorders as the preferred focused-window border implementation rather than
building another Hammerspoon overlay. Define a Catppuccin-inspired configuration
with a rounded style, configurable width, active and inactive colors, and an app
blacklist. Install it through Homebrew, keep `bordersrc` in the dotfiles, and make
starting it as a login service optional. Document that the one-time setup is
persistent but the lightweight border service must keep running to follow focus.

Only consider an `hs.canvas` border as a fallback. If used, subscribe solely to
the window events required to update the visual border; it must never move or
reflow windows and must be possible to disable completely.

### Application title bars and decorations

There is no safe, supported global macOS setting for removing title bars from all
third-party windows. Apply decoration changes per application where the application
supports them:

- Kitty may use `hide_window_decorations titlebar-only` to hide its title bar while
  retaining rounded corners. Verify margins and text clipping before enabling it.
- Reduce VS Code's title-bar chrome with supported settings such as its custom title
  bar and optional Command Center or layout-control visibility. Do not promise a
  completely borderless window where VS Code or macOS does not support one.
- Keep Chrome's normal window decoration unless a specific app-window workflow is
  requested; Chrome has no suitable global borderless setting for ordinary windows.

Do not cover title bars with fake overlays. Do not use SIMBL-style injection,
protected-system-file patches, or reduced macOS security merely for theming.

### Hammerspoon chooser and launcher theme

Create one shared native `hs.chooser` appearance helper and apply it consistently
to Comma Selection, `P`, application-instance selection, and the shortcut catalog.
Use the native chooser for the first implementation so the current speed and
keyboard behavior remain intact. The theme should support:

- dark presentation and Catppuccin-inspired foreground and secondary colors;
- consistent width, row count, density, and styled text;
- application icons where they improve scanning performance;
- a setting to hide window titles entirely or show them only as subdued subtext;
- the existing forward and reverse cycle behavior and acceptance on MainMod release.

The Hammerspoon application launcher uses the shared native chooser helper. The native chooser cannot
provide fully arbitrary background colors, window shapes, or container-level
rounded-corner styling; keep that limitation explicit.

As an optional second phase, evaluate a pre-created `hs.webview` or similarly
custom launcher only if the themed native chooser is still visually insufficient.
That implementation would need to preserve startup speed, filtering, keyboard
navigation, cycle direction, application icons, and selection semantics. Do not
replace the native chooser solely for cosmetic completeness.

### macOS desktop appearance

Offer optional persistent settings for automatically hiding the Dock and menu bar,
reducing Dock clutter, and reducing nonessential animation where supported by the
installed macOS version. Before applying undocumented `defaults` keys, capture the
existing values. Provide a restore command and restart only the affected processes,
such as Dock or SystemUIServer. Treat internal defaults as version-sensitive and
verify them on the target macOS release before enabling them.

### Architecture boundary

This optional appearance work must follow the established architecture:
Hammerspoon owns explicit Accessibility geometry, interaction and chooser UI;
JankyBorders may own the optional focus border. Stage Manager, Mission Control,
Alfred, Raycast, AeroSpace and Yabai remain outside this work. Keep installation,
activation and rollback scriptable and documented.
