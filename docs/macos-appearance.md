# Optional macOS appearance layer

The appearance layer adds Catppuccin styling without changing the Hammerspoon
navigation model. It is split into independently disableable pieces and does not
use Stage Manager, Mission Control, Spaces or another window manager.

## Window borders

Hammerspoon draws rounded Catppuccin frames for active layout slots only. Green
marks the slot occupied by the focused window and Pink marks the other slots.
The Green frame follows macOS's global window focus, so inactive displays contain
only Pink frames. Untracked windows have no frame.
`config.appearance.layoutBorders` controls the feature, colors, width, radius and
offset; set `enabled = false` to remove it completely. The configured width is 4.5
points.

Frames belong to slot geometry rather than window objects. A focus change updates
only the colors. When Comma Selection replaces a slot occupant, an unchanged slot
needs no canvas geometry update at all. Frames are rebuilt only when the explicit
layout geometry changes. Focusing an untracked window, manually moving a tracked
window, changing its native lifecycle state or changing the display configuration
invalidates the affected layout and removes its frames.

JankyBorders remains an optional simpler two-state alternative. Homebrew installs
`borders`, but the main setup does not start its service. Its Catppuccin
configuration is stored in `home/.config/borders/bordersrc`. Do not run it together
with Hammerspoon frames: JankyBorders cannot distinguish layout membership, and
the two border layers would overlap.

```sh
setup/macos/setup-appearance.sh borders-start
setup/macos/setup-appearance.sh borders-stop
```

The Homebrew service starts at login and must remain running to follow global
focus. Before enabling it, set the Hammerspoon frame configuration to
`enabled = false` and reload Hammerspoon.

## Native choosers

Comma Selection, `P`, instance selection, the application launcher and the
shortcut catalog all use the shared native `hs.chooser` helper. It applies a dark
presentation with Catppuccin Text and Subtext colors, consistent dimensions and
application icons. Window names are the primary row and titles are subdued
subtext. Set `config.chooser.showWindowTitles = false` to omit titles entirely.

The native chooser deliberately remains in use to preserve filtering speed and
selection behavior. Its container background, shape, row height and corners are
controlled by macOS and cannot be themed precisely.

## Application decorations

Kitty has an opt-in macOS configuration with `titlebar-only`, a four-point margin
and top-left placement to retain rounded corners without clipping terminal text.
Enable or disable it independently:

```sh
setup/macos/setup-appearance.sh kitty-enable
setup/macos/setup-appearance.sh kitty-disable
```

The change applies to new Kitty windows. VS Code uses its supported custom title
bar while Command Center, layout controls and navigation controls remain hidden in
the tracked user settings. This reduces chrome but does not make the window fully
borderless. Chrome retains its native decoration. No title-bar overlays, injected
plugins or reduced security settings are used.

## Desktop settings and restore

The optional system layer hides the Dock and menu bar, hides recent applications
in the Dock and shortens nonessential window and Dock animation. Before the first
apply, the script records every affected value in
`~/.local/state/dotfiles/macos-appearance/restore-defaults.sh`. Apply and restore
are idempotent, and only Dock and SystemUIServer are restarted.

```sh
setup/macos/setup-appearance.sh system-apply
setup/macos/setup-appearance.sh system-restore
```

The combined commands also enable or disable the Kitty layer:

```sh
setup/macos/setup-appearance.sh apply
setup/macos/setup-appearance.sh restore
setup/macos/setup-appearance.sh status
```

`expose-animation-duration` and `NSAutomaticWindowAnimationsEnabled` are internal,
version-sensitive defaults. They are intentionally absent from nix-darwin so that
a later rebuild does not overwrite either the optional state or its restored
baseline.
