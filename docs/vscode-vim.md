# VS Code Vim

## Target state

VS Code should provide the same physical keyboard workflow on NixOS and macOS
while keeping editor behavior close to stock Vim. Vim motions, operators, modes,
registers and control-key meanings remain the baseline. VS Code-specific bindings
are exceptions and should exist only when they provide material workbench value.

The accepted non-default presentation and configuration choices are:

- Relative line numbers support counted Vim motions without changing editing
  semantics.
- Space is the shared VSCodeVim and Neovim leader so future intentional mappings
  can use the same shape in both editors.

New mappings must not replace a useful Vim command without an explicit trade-off.
Prefer VSCodeVim mappings for modal behavior and `keybindings.json` for workbench
behavior that needs VS Code context. Physical shortcuts must behave identically
on NixOS and macOS even where the platform defaults use different modifiers.
The fixed ZMK layout is explicitly designed to make both Ctrl chords and modal
sequences accessible; its contract is documented in
[Keyboard input model](keyboard-input.md).

## Current state

VSCodeVim uses its defaults except for Space as leader and one compatibility
mapping: Insert-mode `Ctrl+J` maps non-recursively to `<Enter>`. This preserves
Vim's standard line-break behavior while allowing the same physical shortcut to
remain a workbench terminal control outside Insert mode. There are no Normal,
Visual or command-line mode remappings. VS Code shows relative line numbers;
`vim.smartRelativeLine` is deliberately not enabled.

The shared `home/.config/Code/User/keybindings.json` retains these explicit
cross-platform workbench exceptions:

| Physical shortcut | Action | Difference from defaults |
| --- | --- | --- |
| `Ctrl+P` | Open Quick Open | Matches the Linux default; replaces Vim `Ctrl+P`; preserves the physical key on macOS |
| `Ctrl+Shift+P` | Open the Command Palette | Matches the Linux default and preserves the physical key on macOS |
| `Ctrl+,` | Select the previous MRU editor, then continue forward | Custom on both platforms; replaces the VS Code Settings shortcut |
| `Ctrl+Shift+,` | Select the least-recently-used editor, then continue backward | Custom on both platforms |
| `Ctrl+E` outside editor text and terminal focus | Return focus to the active editor group | Custom on both platforms; Vim and the shell retain `Ctrl+E` |
| `Ctrl+J` | Toggle the integrated terminal, including from terminal focus; create it if needed | Custom outside VSCodeVim Insert mode; Insert mode maps it to VSCodeVim `<Enter>` |
| `Ctrl+Shift+J` | Create an integrated terminal | Custom outside terminal focus and VSCodeVim Insert mode |
| `Ctrl+Shift+F` | Find in Files | Explicit on both platforms outside terminal focus, including editor text |
| `Ctrl+'` | Toggle the maximized panel | Custom on both platforms |

MRU means most recently used. The editor chooser follows focus history rather
than tab position. `Ctrl+J` is workbench-owned outside VSCodeVim Insert mode,
including terminal focus; `Ctrl+Shift+J` still yields to the terminal. The
explicit Insert-mode route hands `Ctrl+J` back to VSCodeVim, where the
compatibility mapping gives it the same behavior as `<Enter>` instead of
bypassing VSCodeVim's cursor state. The existing workbench exceptions remain
available in their documented editor contexts; no additional GUI editing
translation applies in any Monaco editor mode, including Insert mode.

Shared context-bound rules explicitly define the same `Ctrl` actions on Linux
and macOS outside editor text and terminal focus, including Linux defaults:
select all, copy/cut/paste, undo/redo, find, save/save-as/save-all, close, new/open,
sidebar and view commands, editor-group
focus, splitting and zoom. Hammerspoon additionally translates editing and text
navigation in native and extension webview text inputs, including Codex Chat;
its Accessibility checks exclude Monaco and the integrated terminal.

`Ctrl+Shift+F` binds `workbench.action.findInFiles`, which owns Edit > Find in
Files. The Search sidebar also retains a `workbench.view.search` binding with
VS Code's own nonmatching `neverMatch =~ /doesNotMatch/` condition for its shortcut
label. This keeps both labels on Ctrl without two competing executable bindings.

While the integrated terminal has focus, `Ctrl+J` toggles it closed. This
reserves that key for the workbench rather than shell/TUI input; Enter still
submits shell input. Quick Open, palette, MRU, focus, new-terminal and
panel-maximization controls continue to yield to the shell. `Ctrl+P` reaches Zsh
history and `Ctrl+E` reaches line-end navigation. `Ctrl+Shift+C/V` use VS Code's
terminal copy/paste commands on both platforms, matching Kitty. Explicit
empty-command rules for terminal-focused `Ctrl+A..Z` except `Ctrl+J`, the former
workbench keys and `Ctrl+Shift+P/J` stop fallback to built-in or extension
bindings, including VS Code's `Ctrl+K` chord prefix. The terminal receives the
original key event rather than a hard-coded escape sequence.

## Ownership

- `home/.config/Code/User/settings.json` owns shared VS Code and VSCodeVim
  settings.
- `home/.config/Code/User/keybindings.json` owns context-bound workbench
  shortcuts, shared `Ctrl` actions outside the editor and terminal clipboard actions.
- `home/.config/nvim/` owns Neovim behavior independently. Shared conventions
  such as the Space leader should remain aligned deliberately rather than by
  loading one editor's configuration into the other.
- Hammerspoon handles native and webview text fields on macOS, but leaves Monaco
  editors and the integrated terminal to VS Code and VSCodeVim.

The macOS application boundary is documented in
[macOS keyboard parity](macos-keyboard-parity.md#vs-code).
