# Keyboard input model

## Target state

The Kinesis Advantage 360 Pro ZMK layout is the fixed physical input contract
for the workflow. It is deliberately optimized for shortcuts: thumb-held
modifiers, thumb-held layers and mirrored navigation make both chords and
sequences accessible without expanding the active typing area beyond three
alphabetic rows.

Application and operating-system configuration should adapt to this contract.
A shortcut conflict in Hyprland, Hammerspoon, Zellij, Neovim or VS Code is not
by itself a reason to change the firmware layout.

Shortcut parity means preserving the same physical gesture and action on NixOS
and macOS. The operating systems may receive different native key events when
that is necessary to produce the same result.

## Ownership

- The external repository at `~/projects/temp/Adv360-Pro-ZMK-hts` owns the ZMK
  firmware and is not managed by these dotfiles.
- `config/adv360.keymap` is the active keymap source. Both split-half keymaps
  include it directly.
- `config/keymap.json` represents an older four-layer layout and must not be
  treated as the source of truth when reasoning about current shortcuts.
- Hyprland and Hammerspoon own global workflow shortcuts after the firmware has
  emitted its key events.
- Hyprland sets the Cherry MW 8C Advanced pointer sensitivity to `-0.5` for this
  mouse only; other pointing devices keep the global default.
- Terminals and Zellij own terminal multiplexing; Neovim and VSCodeVim own
  modal editor behavior.

## Physical shortcut contract

The default layer keeps QWERTY on the three alphabetic rows and concentrates
the workflow controls on the thumbs and outer keys.

| Physical gesture | Emitted behavior |
| --- | --- |
| Tap / hold left Backspace thumb | `Backspace` / `Ctrl` |
| Tap / hold left Delete thumb | `Delete` / Left layer |
| Tap / hold right Enter thumb | `Enter` / Right layer |
| Tap / hold right Space thumb | `Space` / `Ctrl+Alt+GUI` |
| Outer lower-row keys | Left and right `Shift` |
| Outer left home-row key | Left `Alt` |
| Outer left upper-row key | Left `GUI` |

`GUI` becomes Super on NixOS and Command on macOS. Holding Space therefore
emits the existing `mainMod`: `Super+Ctrl+Alt` on NixOS and
`Command+Control+Option` on macOS.

The Left layer provides programming symbols, brackets, `Esc`, `Tab` and direct
modifiers. The Right layer provides arrows on the physical `H/J/K/L` positions
as well as Home, Page Down, Page Up and End. Separate layers provide numbers,
mouse control, macros, function keys, a keypad and firmware controls.

The dual-role Ctrl and Space keys use a 150 ms balanced hold-tap decision, a
250 ms quick-tap window and a 200 ms prior-idle condition. These timings are
part of the established keyboard behavior. They are relevant when diagnosing a
missed chord, but they do not make Ctrl shortcuts second-class inputs.

## Shortcut design consequences

- Existing `Ctrl` habits such as `Ctrl+C`, `Ctrl+V`, `Ctrl+P` and
  `Ctrl+Shift+P` remain first-class workflow inputs. They should not be removed
  merely to make an application more theoretically Vim-like.
- Native Vim motions, operators and multi-key commands remain valuable because
  they are portable to plain Vim and compose naturally with the three-row
  layout. This is a portability choice, not a rejection of chords.
- Space as the Neovim and VSCodeVim leader complements the firmware: tapping
  Space emits the leader key, while holding it emits `mainMod`.
- Application-specific conflicts should be resolved at the narrowest owner.
  Global translation must not consume terminal or editor keys that the focused
  application needs.
- Shortcut descriptions should document the emitted logical keys while design
  decisions should also consider the physical thumb-and-layer gesture.

## Zellij boundary

Nix installs Zellij on both NixOS and macOS. The tracked
`home/.config/zellij/config.kdl` keeps appearance choices and inherits the
installed Zellij keybindings. Zellij starts in Normal mode. Its default
`Ctrl+P`, `Ctrl+T`, `Ctrl+S` and other mode keys belong to Zellij there;
`Alt+F` also toggles floating panes. These keys cannot simultaneously reach Zsh
or Neovim. `Ctrl+G` enters Locked mode, where Zellij passes the other keys to
the focused shell or TUI; another `Ctrl+G` returns to Normal mode. Use Locked
mode when a Zsh or Neovim binding conflicts with a Zellij default. The exact
default set follows the installed version; see the
[Zellij keybinding reference](https://zellij.dev/documentation/keybindings).

VS Code owns `Ctrl+J` for its integrated terminal outside VSCodeVim Insert mode,
including when the terminal has focus. In Insert mode, VSCodeVim maps `Ctrl+J`
to `<Enter>`. Quick Open, the Command Palette, editor and view focus, and Save All
also work from terminal focus. Other shell/TUI `Ctrl` inputs remain terminal-owned,
while `Ctrl+Shift+C/V` are VS Code terminal clipboard actions. Additional macOS
GUI editing translation excludes every Monaco editor mode and terminal focus.
