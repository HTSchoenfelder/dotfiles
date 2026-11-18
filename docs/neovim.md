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
- `Space T W` to toggle word-boundary wrapping in the current window.
- Default swap-file recovery behavior.

There are no custom window-navigation, clipboard, Visual-mode, test or Git
mappings. `Space T W` is a Normal-mode editor toggle for `wrap`, `linebreak` and
`breakindent` in the current window. `Ctrl+P` opens Telescope's file finder to
match the physical VS Code shortcut on NixOS and macOS. Zellij's `unlock-first`
preset starts in Locked mode, where `Ctrl+P` reaches Neovim directly. Direct
`Alt+H/J/K/L` navigation belongs to Zellij even in Locked mode; on macOS use
left Option, while right Option remains available for AltGr characters.

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

## Isolated LazyVim test

The optional LazyVim starter lives outside this repository in
`${XDG_CONFIG_HOME:-$HOME/.config}/nvim-lazyvim`. Start it with
`NVIM_APPNAME=nvim-lazyvim nvim`, or the `lazyvim` shell alias. Plain `nvim`
continues to use the configuration described above. The separate app name also
separates plugins, cache and state; it does not restrict access to project files.

The starter keeps its original configuration, including LuaRocks support.
Both Nix package lists supply the external health-check and preview tools:

| Package / command | Purpose |
| --- | --- |
| `ripgrep` / `rg`, `fd` | Picker search |
| `imagemagick` / `magick` | Image conversion |
| `lua51Packages.luarocks` / `luarocks` | Lua 5.1 plugin dependencies |
| `lua5.1` | Lua 5.1 compatibility command; the existing `lua` stays unchanged |
| `ghostscript` / `gs` | PDF previews |
| `tectonic` | LaTeX previews |
| `mermaid-cli` / `mmdc` | Mermaid previews |

On NixOS, Mermaid CLI uses the package's Chromium dependency. On macOS, only
the `mmdc` wrapper sets `PUPPETEER_EXECUTABLE_PATH` to the installed
`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`; other Puppeteer
processes keep their own browser configuration. Tectonic may download TeX assets
when first rendering a document.

After changing packages, activate them with `nixbuild` on NixOS or `nixbuildmac`
on macOS, then restart the test instance. If health checks still cannot find a
declared tool, inspect the active system and the editor's `PATH` before adding
duplicate package declarations.

Use `:LazyHealth` in the test instance and save its report with
`:w /tmp/lazyvim-health.txt`. Snacks checks image dependencies even when its
image module is disabled. Additional Tree-sitter parsers for image rendering
remain plugin-managed; installing system tools does not enable the image module
or change the starter's parser selection. Which-key keymap-overlap notices and
Blink's dynamically enabled source notice are informational; keep the default
mappings and sources unless their actual behavior needs changing.
