# Neovim

## Target state

Neovim should remain close to its native editing model and expose every added
behavior intentionally. Core motions, operators, modes, registers, window
commands and current built-in LSP mappings form the baseline. Plugins should add
a capability rather than replace a second set of native commands.

The configuration uses the same Space leader and relative-line presentation as
VSCodeVim. This aligns the two editors without requiring them to share an
implementation or every command.

The fixed ZMK layout supports both native Vim sequences and intentional Ctrl
chords. Neovim stays close to its defaults for portability, not because chords
are considered unsuitable for the keyboard. The physical input contract is
documented in [Keyboard input model](keyboard-input.md).

## Ownership

- Nix installs Neovim, language servers, formatters and linters on both NixOS
  and macOS.
- `lazy.nvim` installs Neovim plugins only.
- Neovim owns editing behavior, native LSP mappings, manual completion and
  buffers, windows and tabs.
- Project shells may supply additional project-specific executables, but the
  baseline configuration must start without them.

## Current state

The core configuration intentionally contains only:

- Space as global and local leader.
- Absolute current-line and relative surrounding-line numbers.
- Two-space, space-based indentation.
- Default swap-file recovery behavior.

There are no custom window-navigation, clipboard, Visual-mode, test or Git
mappings. `Ctrl+P` is the one direct Normal-mode exception: it opens Telescope's
file finder to match the physical VS Code shortcut on NixOS and macOS.

The active plugin capabilities are:

| Capability | Implementation |
| --- | --- |
| Theme | Catppuccin Mocha |
| Syntax and indentation | Tree-sitter parsers for the configured languages |
| File and picker search | Telescope with `Ctrl+P`; other pickers remain available through `:Telescope` |
| Language intelligence | Native Neovim LSP with configs supplied by `nvim-lspconfig` |
| Formatting | `conform.nvim`, invoked explicitly with `:Format` |
| Ruby linting | `nvim-lint` after reading or writing a Ruby buffer |

Neovim's current native LSP mappings are left unchanged. Important examples are
`K` for hover, `grr` for references, `gri` for implementation, `grn` for rename,
`gra` for code actions, `gO` for document symbols, and `[d` / `]d` for diagnostics.
Go to definition remains available through the tag-aware `Ctrl+]` behavior.

LSP completion initially uses Neovim's native manual path: `Ctrl+X Ctrl+O` opens
omni-completion and `Ctrl+Y` accepts a selected item. Automatic completion and a
snippet collection are deliberately deferred until their desired behavior is
clear.

## Deliberately removed tutorial layers

The previous configuration combined two file explorers, two window-navigation
layers, a startup dashboard, a completion framework plus snippet collection,
two Git plugins, tmux-specific test execution and a Swagger preview plugin. They
were removed from the baseline because their workflows had not been selected
deliberately. Any of them can return when a concrete need justifies it.
