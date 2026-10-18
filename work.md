# Work

This file is the single place for postponed work and the macOS test procedure.
Backlog entries are notes, not authorization to implement them; take one up only
when Henrik explicitly requests it. The test procedure can be run when requested.

## Pending work

### macOS keyboard parity

#### Resolve VS Code shortcut collisions

Audit editor, Vim, list, Quick Pick, webview and integrated-terminal contexts.
`Ctrl+H/L` currently work in VSCodeVim Normal mode but not consistently in other
surfaces. Reduce duplicated keybindings, add precise `when` clauses and build an
explicit conflict matrix without stealing shell or modal keys.

#### Decide Chrome `Ctrl+Click` ownership

The current Hammerspoon event tap handles key-down events, not mouse clicks.
Decide whether `Ctrl+Click` belongs in Hammerspoon or a separately designed
physical-input layer.

#### Verify application input boundaries

Add a manual verification matrix for native Cocoa inputs, Chrome page and address
fields, VS Code editor/Vim/list/terminal contexts, Kitty and Secure Input.
Automated event tests cannot prove every application boundary.

### Optional system decision

GNOME Keyring currently owns the Secret Service portal. Decide separately whether
KeePassXC should ever become its backend; do not enable a competing provider by
accident.

## macOS tests

Run these checks on the Mac after changes to Hammerspoon navigation. First verify
that `~/.hammerspoon` uses this checkout and that Hammerspoon has macOS
Accessibility permission. Use disposable app windows for the live checks because
they move, resize and close windows. `mainMod` means `Option + Control + Command`.
The app keys are listed in the
[README quick reference](readme.md#macos--hammerspoon-quick-reference).

### Automated checks

From the repository root, check Lua syntax and run all mocked Hammerspoon tests.
The macOS Nix configuration provides `lua` and `luac`; these commands do not need
a running Hammerspoon session:

```sh
cd ~/dotfiles
(
  set -e
  find home/.hammerspoon -name '*.lua' -exec luac -p {} +
  for test in tests/hammerspoon_*_test.lua; do
    lua "$test"
  done
)
```

### Live checks

Connect two displays, reload Hammerspoon from its menu to clear the in-memory
slot state, and keep the Hammerspoon Console open for Lua or Accessibility errors.

1. Select an app with `mainMod + app key`. Select a different app with
   `mainMod + S + app key`: it fills the other slot without moving focus.
   `mainMod + F + S + app key`: it chooses an instance for the other slot.
   A plain app key then replaces the focused slot without changing the slot count.
   `mainMod + M` changes slot focus; `mainMod + N` swaps contents while retaining
   the focused side. Check the Green active frame and Pink inactive frame.
2. Press `mainMod + /` and `mainMod + Shift + /` in turn. The display changes to
   one slot and back to two, refilling the other side from recent non-slot windows
   if one is available. In a one-slot layout, `S` plus an app key also opens the
   second slot. `mainMod + .`, then `M`, toggles 70:30 and 50:50 on that display.
3. Press `mainMod + H` to change the active display. Repeat with no slot window
   on the target display: its empty slot gets the Green frame even though native
   keyboard focus cannot move there. The next app selection fills that slot.
4. Use `mainMod + P` to select a window already in a slot on the other display;
   its source slot becomes vacant and the replaced window remains native on the
   original display. Check `mainMod + S + P` for the other slot and its
   focused-application filter with `mainMod + F + S + P`.
   Close a slot window with `mainMod + W`: a recent non-slot window refills it.
   With no replacement available, the side stays vacant until a normal window
   arrives. Other windows are neither minimized nor moved to Parking.
5. Check `mainMod + F + app key` and Comma Selection: the chosen window fills the
   intended slot, and Comma Selection accepts on `mainMod` release. Reload
   Hammerspoon once more and confirm that the in-memory slot state resets.
6. Use `mainMod + Y` and confirm that Play/Pause, Next and Previous are followed
   by Spotify as the last entry. The Hyprland-only `I` and `U` PWA groups cannot
   be tested here until their macOS Chrome-PWA bundle IDs are configured.
7. Copy two text values and an image outside a password manager. Press
   `mainMod + V`, filter the chooser and select each older item in turn. The
   chooser closes, the original window regains focus and the selected text or
   image is pasted. Copy a value in KeePassXC and confirm it does not appear.
   Reload Hammerspoon and confirm that the clipboard history is empty apart from
   the pasteboard item current at reload time.

### Failure handling and report

When running this as a coding task, fix failures in the repository, update tests
and affected documentation, and rerun the relevant checks plus `git diff --check`.
Report the automated results, which live cases were actually observed on macOS,
any Hammerspoon Console errors, and any cases that could not be verified. Do not
claim a live pass from mocked tests alone. Do not commit changes unless requested.
