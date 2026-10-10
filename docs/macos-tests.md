# macOS tests

Run these checks on the Mac after changes to Hammerspoon navigation. First verify
that `~/.hammerspoon` uses this checkout and that Hammerspoon has macOS
Accessibility permission. Use disposable app windows for the live checks because
they move, resize and close windows. `mainMod` means `Option + Control + Command`.
The app keys are listed in the [README quick reference](../readme.md#macos--hammerspoon-quick-reference).

## Automated checks

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

## Live checks

Connect two displays, reload Hammerspoon from its menu to clear the in-memory
slot state, and keep the Hammerspoon Console open for Lua or Accessibility errors.

1. Select an app with `mainMod + app key`. Select a different app with
   `mainMod + Shift + app key`: it fills the other slot without moving focus.
   A plain app key then replaces the focused slot without changing the slot count.
   `mainMod + M` changes slot focus; `mainMod + N` swaps contents while retaining
   the focused side. Check the Green active frame and Pink inactive frame.
2. Press `mainMod + /` and `mainMod + Shift + /` in turn. The display changes to
   one slot and back to two, refilling the other side from recent non-slot windows
   if one is available. In a one-slot layout, Shift plus an app key also opens the
   second slot. `mainMod + .`, then `M`, toggles 70:30 and 50:50 on that display.
3. Press `mainMod + H` to change the active display. Repeat with no slot window
   on the target display: its empty slot gets the Green frame even though native
   keyboard focus cannot move there. The next app selection fills that slot.
4. Use `mainMod + P` to select a window already in a slot on the other display;
   the two slot contents swap. Check `mainMod + Shift + P` for the other slot.
   Close a slot window with `mainMod + W`: a recent non-slot window refills it.
   With no replacement available, the side stays vacant until a normal window
   arrives. Other windows are neither minimized nor moved to Parking.
5. Check `mainMod + F + app key` and Comma Selection: the chosen window fills the
   intended slot, and Comma Selection accepts on `mainMod` release. Reload
   Hammerspoon once more and confirm that the in-memory slot state resets.

## Failure handling and report

When running this as a coding task, fix failures in the repository, update tests
and affected documentation, and rerun the relevant checks plus `git diff --check`.
Report the automated results, which live cases were actually observed on macOS,
any Hammerspoon Console errors, and any cases that could not be verified. Do not
claim a live pass from mocked tests alone. Do not commit changes unless requested.
