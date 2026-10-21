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

The shared `home/.config/Code/User/keybindings.json` contains only these explicit
cross-platform exceptions:

| Physical shortcut | Action | Difference from defaults |
| --- | --- | --- |
| `Ctrl+P` | Open Quick Open | Matches the Linux default; replaces Vim `Ctrl+P`; preserves the physical key on macOS |
| `Ctrl+Shift+P` | Open the Command Palette | Matches the Linux default and preserves the physical key on macOS |
| `Ctrl+,` | Select the previous MRU editor, then continue forward | Custom on both platforms; replaces the VS Code Settings shortcut |
| `Ctrl+Shift+,` | Select the least-recently-used editor, then continue backward | Custom on both platforms |
| `Ctrl+E` outside editor text | Return focus to the active editor group | Custom on both platforms; Vim retains `Ctrl+E` while editing |
| `Ctrl+J` while a terminal exists | Toggle the integrated terminal | Custom outside VSCodeVim Insert mode; Insert mode maps it to VSCodeVim `<Enter>` |
| `Ctrl+Shift+J` | Create an integrated terminal | Custom except in VSCodeVim Insert mode |
| `Ctrl+'` | Toggle the maximized panel | Custom on both platforms |

MRU means most recently used. The editor chooser follows focus history rather
than tab position. The J shortcuts are workbench-owned outside VSCodeVim Insert
mode and remain available while the integrated terminal has focus. The explicit
Insert-mode route hands `Ctrl+J` back to VSCodeVim, where the compatibility
mapping gives it the same behavior as `<Enter>` instead of bypassing VSCodeVim's
cursor state. All other editor, workbench, list, Explorer and terminal keys come
from VS Code, VSCodeVim and the platform defaults.

## Ownership

- `home/.config/Code/User/settings.json` owns shared VS Code and VSCodeVim
  settings.
- `home/.config/Code/User/keybindings.json` owns the minimal cross-platform
  shortcut exceptions.
- `home/.config/nvim/` owns Neovim behavior independently. Shared conventions
  such as the Space leader should remain aligned deliberately rather than by
  loading one editor's configuration into the other.
- Hammerspoon handles native and webview text fields on macOS, but leaves Monaco
  editors and the integrated terminal to VS Code and VSCodeVim.

The macOS application boundary is documented in
[macOS keyboard parity](macos-keyboard-parity.md#vs-code).
