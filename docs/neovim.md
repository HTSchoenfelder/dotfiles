# Neovim

## Active configuration

LazyVim is the standard configuration in `home/.config/nvim/`. Plain `nvim`
and the `lazyvim` shell alias both start it through the normal `nvim` app name.
The former isolated `nvim-lazyvim` test configuration is no longer used.

Catppuccin Mocha is selected through LazyVim's `colorscheme` option in
`lua/plugins/catppuccin.lua`. LazyVim supplies the Catppuccin plugin and its
integrations. The Snacks explorer shows hidden files and directories (names
starting with `.`) by default, configured in `lua/plugins/snacks.lua`.
The remaining editor behavior follows LazyVim's defaults,
including Space as leader, relative line numbers, picker, completion, LSP,
formatting and keymaps. The starter's `lua/plugins/example.lua` returns an empty
spec and does not activate its example settings.

The fixed ZMK layout supports native Vim sequences and Ctrl chords. The physical
input contract and Zellij's terminal navigation are documented in
[Keyboard input model](keyboard-input.md). Direct `Alt+H/J/K/L` navigation belongs
to Zellij even in Locked mode; on macOS use left Option, while right Option
remains available for AltGr characters.

## Ownership

- Nix installs Neovim and external tools on both NixOS and macOS, including
  declared language servers, formatters, linters and preview dependencies.
- `lazy.nvim` manages editor plugins from the repository's LazyVim configuration.
- LazyVim supplies editor defaults and retains its default Mason integration
  for language tools; no repository override disables Mason installation.
- Project shells may supply additional project-specific executables.

## Reference configuration

The previous custom configuration is preserved in `home/.config/nvim_t/` only
for looking up earlier settings. It is not loaded by the standard configuration.
Start it explicitly with:

```sh
NVIM_APPNAME=nvim_t nvim
```

The separate app name keeps its plugins, cache and state separate from LazyVim.
Its Telescope `Ctrl+P` mapping, `Space T W` wrapping toggle, native manual
completion and custom LSP, formatting and Ruby linting setup belong to this
reference configuration, not the active LazyVim setup.

## External tools and health checks

Nix supplies LuaRocks, Lua 5.1 compatibility and preview tools on both platforms.
LazyVim keeps LuaRocks support enabled. Both Nix package lists supply the external
health-check and preview tools:

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
on macOS, then restart Neovim. If health checks still cannot find a
declared tool, inspect the active system and the editor's `PATH` before adding
duplicate package declarations.

Use `:LazyHealth` and save its report with
`:w /tmp/lazyvim-health.txt`. Snacks checks image dependencies even when its
image module is disabled. Additional Tree-sitter parsers for image rendering
remain plugin-managed; installing system tools does not enable the image module
or change LazyVim's parser selection. Which-key keymap-overlap notices and
Blink's dynamically enabled source notice are informational; keep the default
mappings and sources unless their actual behavior needs changing.
