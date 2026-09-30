# Optional macOS appearance layer

The appearance layer adds Catppuccin styling without changing the Hammerspoon
navigation model. It is split into independently disableable pieces and does not
use Stage Manager, Mission Control, Spaces or another window manager.

## Window borders

Hammerspoon draws rounded Catppuccin frames only around windows currently retained
by its per-display layouts. Surface2 marks inactive layout members and Mauve marks
the focused member. `config.appearance.layoutBorders` controls the feature, colors,
width, radius and offset; set `enabled = false` to remove it completely. The module
subscribes only to layout changes and native window lifecycle, visibility, focus
and move events. It never moves or resizes a window.

JankyBorders remains an optional global focus ring. Homebrew installs `borders`,
but the main setup does not start its service. Its Catppuccin configuration is
stored in `home/.config/borders/bordersrc`; the inactive color is transparent so
that Hammerspoon remains responsible for the selective layout frames.

```sh
setup/macos/setup-appearance.sh borders-start
setup/macos/setup-appearance.sh borders-stop
```

The Homebrew service starts at login and must remain running to follow global
focus. When it is enabled, `highlightFocused = false` may be used in the
Hammerspoon appearance configuration if only one active ring is desired.

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
