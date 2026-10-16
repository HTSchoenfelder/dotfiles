# Dotfiles

Personal NixOS, Hyprland and macOS configuration for Henrik's desktop workflow.

## Workflow goal

Hyprland is the reference environment for building Henrik's keyboard-driven
workflow. The macOS configuration reproduces that interaction model through
Hammerspoon and native Accessibility so the same muscle memory applies on both
systems. Shortcut shapes, modifier combinations, navigation semantics and
selection flows should remain aligned.

Reliable platform-native behavior takes precedence when exact parity would be
fragile. Intentional differences that affect muscle memory must stay explicit and
documented.

Keyboard parity extends beyond window management: Linux-shaped `Ctrl` editing,
text navigation and application shortcuts should retain their physical keys even
where macOS expects `Command` or `Option`. The current implementation and remaining
VS Code and application-specific gaps are tracked in the
[macOS keyboard parity](docs/macos-keyboard-parity.md) document.

Hammerspoon is the only macOS workflow and window-management process. It owns
shortcuts, modes, choosers, application intentions, MRU state, MIDI integration,
passive two-slot geometry and layout-slot frames through native windows.
It changes frames only for explicit actions and does not use AeroSpace, Stage
Manager, Mission Control or Spaces. JankyBorders remains an optional two-state
alternative but must not run alongside Hammerspoon's window frames. See the
[macOS window-management architecture](docs/macos-window-management.md) and
[optional appearance layer](docs/macos-appearance.md).

Both platforms retain one or two slots per display, including temporary vacancies.
App and window selection replaces a slot; Shift targets the other side. Closing a
slot window refills it by focus history. Dot Mode `M` toggles 70:30/50:50. On
macOS, non-slot windows remain native windows and form a logical replacement pool;
there is no Parking workspace.

## NixOS session startup

The login path is deliberately manual: systemd starts `getty@tty1`, PAM login
starts the per-user systemd manager and Zsh, and the shell remains a normal TTY
until `shl` runs `start-hyprland`. Starting Hyprland activates
`hyprland-session.target`, which binds the general `graphical-session.target` to
the compositor lifetime. Exiting Hyprland therefore stops both target-owned sets
of desktop processes without affecting the login shell or system services.

| Owner / trigger | Processes |
| --- | --- |
| System boot targets | `getty@tty1`, NetworkManager, Bluetooth, Avahi and machine-level initialization |
| System socket / D-Bus activation | CUPS, PC/SC and UDisks2 |
| User login / default target | The user D-Bus broker, SSH agent and GNOME Keyring login component |
| User socket activation | PipeWire and PipeWire Pulse; PipeWire starts WirePlumber |
| `graphical-session.target` | Dunst, the Polkit agent, NetworkManager and Blueman applets, Udiskie and Clipse clipboard watchers |
| `hyprland-session.target` | Waybar, Hyprpaper and Hypridle |
| D-Bus activation during the session | XDG Desktop Portal and its GTK and Hyprland backends |
| Hyprland Lua on explicit interaction | Short-lived launchers, screenshots, media commands and requested applications |

NixOS declares packages and units; `systemd --user` supervises long-running
desktop processes. Hyprland-specific daemons use the Hyprland target rather than
direct compositor `exec` calls, so they start only with `start-hyprland`, restart
on failure and stop with the compositor. Hyprland Lua owns compositor behavior
and user-triggered actions, not daemon lifetime.

## Neovim

The repository contains a custom `lazy.nvim` configuration rather than LazyVim.
Nix owns Neovim, language servers, formatters and linters on both platforms;
`lazy.nvim` owns editor plugins only. Native Neovim LSP runs TypeScript, Ruby,
HTML and Lua servers. `conform.nvim` formats with `<leader>gf`, while `nvim-lint`
runs Ruby diagnostics after reading and writing a buffer. Ruby, ERB, Lua and web
formats use Nix-provided tools. Tree-sitter parsers are explicitly managed for
the configured languages.

## macOS / Hammerspoon quick reference

`mainMod` = `Option + Control + Command`. Hammerspoon retains one or two slot sides
per display in memory. Application shortcuts use bundle IDs and the MRU history.
Normal selection replaces the focused side; Shift fills the other side while
retaining focus. `F` opens the instance chooser, including for one instance.

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/I/;/O/U` | Fill the focused slot with Kitty / VS Code / Chrome / Google Chat / Obsidian / KeePassXC / Spotify |
| `mainMod + Shift + app key` | Fill the other slot with a distinct instance; retain focus |
| `mainMod + F + app key` | Choose an application instance for the focused slot |
| `mainMod + P` / `mainMod + Shift + P` | Choose a window for the focused / other slot |
| `mainMod + ,` / `mainMod + Shift + ,` | Choose focused-slot content by MRU forward/backward; release `mainMod` to accept |
| `mainMod + F + ,` | Choose focused-app instances for the focused slot |
| `mainMod + Y` / `mainMod + Shift + Y` | Cycle through Spotify Play/Pause, Next and Previous; release `mainMod` to accept |
| `mainMod + M` | Focus the other occupied slot |
| `mainMod + N` | Swap slot contents while retaining the focused side |
| `mainMod + H` | Focus the other display's slot; show its active frame even when empty |
| `mainMod + /` / `mainMod + Shift + /` | Use one / two slots on the active display |
| `mainMod + .`, then `M` | Toggle the active display between 70:30 and 50:50 |
| `mainMod + W` | Close the focused slot window and refill it from the non-slot MRU pool |
| `mainMod + R` | Toggle the native application launcher |
| `mainMod + Shift + R` | Show the searchable shortcut catalog |
| `mainMod + Backslash` | Toggle the RØDECaster mute state |

Application, window and comma selection use the same compact `hs.chooser`
presentation with Catppuccin text colors, application icons and subdued window
titles. The application launcher lists top-level bundles from standard application
directories. Green marks the active slot, including an empty display selected by
`H`; other retained slots are Pink. Untracked windows have no frame. Both titles
and frames can be disabled in `home/.hammerspoon/config.lua`.

The application launcher also places an existing app window into the captured
focused slot. A newly launched normal window follows the same active-display
state when its native window appears.

Non-slot windows are neither minimized nor moved to a Parking area. A close refills
the vacated side from their MRU order; if none exists, the side remains remembered.
Selecting an occupant on another display swaps the two slot contents. Native
macOS focus cannot move to an empty display, so the active frame and subsequent app
selection follow Hammerspoon's retained display state instead.

## Hyprland quick reference

`mainMod` = `Super + Ctrl + Alt`. Each display retains one or two slots.
The native master layout owns geometry; navigation changes slot contents.
The left slot is the master. The right slot is the only stack window.

### Application selection

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/I/;/O/U` | Fill the focused slot with Kitty / VS Code / Chrome / Google Chat / Obsidian / KeePassXC / Spotify; start the app if needed |
| `mainMod + Shift + app key` | Fill the other slot, creating it if needed; retain focus on the original side |
| `mainMod + F + app key` | Choose an instance for the focused slot |
| `mainMod + Shift + F + app key` | Choose another instance for the other slot; retain focus |
| `mainMod + R` | Toggle the Rofi application launcher |

Normal selection never adds a slot. A Parking or hidden-workspace selection
replaces the target and parks its previous occupant. Selecting a window in another
visible slot swaps the two occupants, including across displays. Selecting the
current occupant does nothing. A window cannot occupy both slots: Shift excludes
the focused instance, chooses another existing instance if available, and otherwise
does nothing when that app already has only the focused instance. If the app is
not running, its window is placed only after it appears; failed or stale launches
do not displace existing slot contents.

### Slot focus and contents

| Shortcut | Action |
| --- | --- |
| `mainMod + P` / `mainMod + Shift + P` | Search for a window for the focused / other slot |
| `mainMod + ,` / `mainMod + Shift + ,` | Select by focus history forward/backward; replace the focused slot on modifier release |
| `mainMod + F + ,` | Select instances of the focused app for the focused slot |
| `mainMod + M` | Focus the other occupied slot on the same display |
| `mainMod + N` | Swap both slot contents; keep focus on the same visual side |
| `mainMod + H` | Focus the most recent slot window on the other display, or the empty display itself |
| `mainMod + W` | Close the focused window and refill its slot from Parking |

`H` preserves the other display's visible workspace and does nothing with one
enabled display. There is no held `G` display modifier or `G + H` / `G + /` action.
The existing Dot Mode project-tool keys are separate from display navigation.
Shift in Comma Selection always means backward, never the other slot.

When any slot window closes, its side is filled by the most recently focused
eligible window in Parking. Other visible windows are never taken for refill.
A focused slot's replacement receives focus; background replacement preserves
keyboard focus. Floating utility windows, native floating dialogs, hidden group
members, special-workspace windows and project overlays are excluded from slot
selection and refill.

If Parking has no replacement, the remaining window temporarily fills the screen.
The missing slot and its side remain remembered; the next available normal window
restores the split. This also works after both slots become vacant. There are no
placeholder windows. Slot vacancies and per-display ratios survive config reloads
within the current compositor session via a private runtime-directory checkpoint.

New normal windows opened outside app shortcuts (including launcher and in-app
new-window actions) fill a remembered vacancy or replace the previously focused
slot. They do not create a third tile. On initial adoption of an older layout,
excess normal windows go to Parking while retaining the master and the focused
window when possible.

### Layout

| Shortcut | Action |
| --- | --- |
| `mainMod + /` | Keep the focused window as the only slot; park the other content without refilling that slot |
| `mainMod + Shift + /` | Use two slots; refill the other side from Parking or remember it until a window appears |
| `mainMod + .`, then `M` | Toggle the focused display between 70:30 and 50:50 |

70:30 always means left 70%, right 30%, regardless of focus. The ratio is remembered
per display even with a single window. `Shift + /` and Shift selection expand a
one-slot layout using that ratio. With a temporarily vacant slot, focus can only
visit occupied slots because native master tiling has no independently focusable
empty slot.

For example, Code left and Chrome right remain a two-slot layout when `J` replaces
Code with Kitty. `Shift + K` then replaces Chrome with Code while focus stays on
Kitty. `N` swaps Kitty and Code while focus stays on the same screen side.

Workspace selection remains `mainMod + B` / `Shift + B`; media selection remains
`mainMod + Y` / `Shift + Y`. `mainMod + Shift + R` opens the shortcut catalog.
The existing workspace reset explicitly restores a single terminal slot.

## Dot mode

Press `mainMod + .`; the top-right `dot mode` notice remains visible until the
next key ends the mode. The macOS implementation uses native `hs.chooser` surfaces
instead of Rofi.

| Key | Action |
| --- | --- |
| `Q` | Capture a region |
| `A` | Capture the focused window |
| `Z` | Capture the focused monitor |
| `B` | Toggle a connected display (Hyprland only) |
| `M` | Toggle the active display split between 70:30 and 50:50 |
| `V` | Toggle a project Neovim overlay |
| `G` | Toggle a project Lazygit overlay |
| `J` | Toggle a project Kitty overlay |
| `W` | Hide all project overlays |
| `E` | Select and insert an emoji |
| `R` | Select a configured command (Hyprland) / reset the current window layout (macOS) |
| `T` | Select and insert a snippet |
| `Escape` | Leave dot mode |

On macOS, project identity is taken from path-based VS Code titles such as
`~/dotfiles | Code`; non-path titles are deliberately rejected.

Dot Mode screenshots from both macOS and Hyprland are stored in `~/screenshots`.

Project overlays use the absolute project path from the active VS Code title and
reuse one Kitty window per project and tool. Toggling an overlay off minimizes
that window with the same shortcut; opening another overlay minimizes the previous
one. Dot Mode actions consume the selected key press and run on release, preventing
a focus-changing overlay action from forwarding either event to a client.

The named Terminal and Parking workspaces remain present while empty. Waybar,
Hyprpaper and Hypridle are bound to `hyprland-session.target` and supervised by
`systemd --user`.

## Application shortcut forwarding

On Hyprland, `Ctrl + P/H/J/K/L` reaches the focused application unchanged. Chrome
maps it to tab search, Back, previous tab, next tab and Forward. The macOS layer
implements the same actions and translates the common Linux-shaped Chrome and
system text shortcuts to their native macOS events. VS Code remains context-owned
for commands, Monaco, Vim and its terminal, while native and webview text inputs
receive the same navigation translation. Its status is documented in
[macOS keyboard parity](docs/macos-keyboard-parity.md).

Media, volume, microphone and brightness hardware keys use their native actions.
The read-only shortcut catalogs use `Shortcut — Description` rows and include
global bindings, modifier combinations, Dot mode and hardware/media bindings.
Hyprland's Lua entry point is `home/.config/hypr/hyprland.lua`; architecture and
interaction notes live in [`docs/hyprland-lua.md`](docs/hyprland-lua.md). The
active macOS responsibility split is documented in
[`docs/macos-window-management.md`](docs/macos-window-management.md). Explicitly
postponed work and the macOS test procedure are tracked in [`work.md`](work.md).
