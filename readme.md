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
App and window selection replaces a slot; held `F` filters application instances,
held `S` targets the other side, and Shift reverses cyclic selection. Closing a
slot window refills it by focus history. Hyprland Dot Mode `/` toggles 70:30/50:50;
macOS currently retains Dot Mode `M`. Its non-slot windows remain native windows
and form a logical replacement pool.

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
Normal selection replaces the focused side; held `S` fills the other side while
retaining focus. Held `F` opens the instance chooser, including for one instance.

An **App Key** is a configured key that identifies either one application or a
small application group while `mainMod` is held. References such as `F + App Key`
and `S + App Key` compose those modifiers with that key; for example,
`mainMod + F + S + K` chooses a VS Code instance for the other slot.

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/I/;/O` | Fill the focused slot with Kitty / VS Code / Chrome / Google Chat / Obsidian / KeePassXC |
| `mainMod + F + app key` | Choose an application instance for the focused slot |
| `mainMod + S + app key` | Fill the other slot with a distinct instance; retain focus |
| `mainMod + F + S + app key` | Choose an application instance for the other slot |
| `mainMod + P` / `mainMod + S + P` | Choose a window for the focused / other slot |
| `mainMod + F + P` / `mainMod + F + S + P` | Choose focused-app windows for the focused / other slot |
| `mainMod + ,` / `mainMod + Shift + ,` | Choose focused-slot content by MRU forward/backward; release `mainMod` to accept |
| `mainMod + F + ,` / `mainMod + F + Shift + ,` | Choose focused-app instances forward/backward |
| `mainMod + S + ,` / `mainMod + F + S + ,` | Choose all / focused-app windows for the other slot |
| `mainMod + Y` / `mainMod + Shift + Y` | Cycle through Spotify, Play/Pause, Next and Previous forward/backward; release `mainMod` to accept |
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
Selecting an occupant on the same display swaps the two slot contents. Selecting
one from another display leaves its source slot vacant and the replaced window
untracked on its original display. Native macOS focus cannot move to an empty
display, so the active frame and subsequent app selection follow Hammerspoon's
retained display state instead.

## Hyprland quick reference

`mainMod` = `Super + Ctrl + Alt`. Each display retains one or two slots.
The native master layout owns geometry; navigation changes slot contents.
The left slot is the master. The right slot is the only stack window. Direct App
Keys are `J` = Kitty / Zellij, `K` = VS Code, `L` = Chrome, `;` = Obsidian and
`O` = KeePassXC. Group App Keys use the same modifier-release selection lifecycle
as Comma Selection and `Y`: `I` cycles Google Chat then Google Meet, while `U`
cycles Gmail then Google Calendar. Shift starts each group from its second entry.

### Application selection

| Shortcut | Action |
| --- | --- |
| `mainMod + J/K/L/;/O` | Fill the focused slot with Kitty / VS Code / Chrome / Obsidian / KeePassXC; start the app if needed |
| `mainMod + I` / `mainMod + Shift + I` | Cycle Chat → Meet / Meet → Chat; release `mainMod` to accept |
| `mainMod + U` / `mainMod + Shift + U` | Cycle Gmail → Calendar / Calendar → Gmail; release `mainMod` to accept |
| `mainMod + F + app key` | Choose an instance for the focused slot |
| `mainMod + S + app key` | Fill the other slot, creating it if needed; retain focus on the original side |
| `mainMod + F + S + app key` | Choose an instance for the other slot; retain focus |
| `mainMod + R` | Toggle the Rofi application launcher |

Normal selection never adds a slot. A Parking or hidden-workspace selection
replaces the target and parks its previous occupant. Selecting the other slot on
the same display swaps both occupants. Selecting from another display parks the
target's previous occupant and leaves the source slot vacant. Selecting the current
occupant does nothing. A window cannot occupy both slots: `S` excludes
the focused instance, chooses another existing instance if available, and otherwise
does nothing when that app already has only the focused instance. If the app is
not running, its window is placed only after it appears; failed or stale launches
do not displace existing slot contents.

### Slot focus and contents

| Shortcut | Action |
| --- | --- |
| `mainMod + P` / `mainMod + S + P` | Search for a window for the focused / other slot |
| `mainMod + F + P` / `mainMod + F + S + P` | Search focused-app windows for the focused / other slot |
| `mainMod + Shift + P` | Show the searchable shortcut catalog |
| `mainMod + Shift + R` | Select and run a configured command |
| `mainMod + ,` / `mainMod + Shift + ,` | Select by focus history forward/backward; replace the focused slot on modifier release |
| `mainMod + F + ,` / `mainMod + F + Shift + ,` | Select focused-app instances forward/backward |
| `mainMod + S + ,` / `mainMod + F + S + ,` | Select all / focused-app windows for the other slot |
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
A targeted refill changes only that slot; an untargeted deferred refill considers
only the active workspace, never remembered vacancies on other displays.
A focused slot's replacement receives focus; background replacement preserves
keyboard focus. Floating utility windows, native floating dialogs, hidden group
members outside the Parking container, special-workspace windows and project
overlays are excluded from slot selection and refill. Parking windows share one
hidden tabbed group so they retain a usable client size while parked; its hidden
members remain selectable.

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
| `mainMod + .`, then `/` | Toggle the focused display between 70:30 and 50:50 |

70:30 always means left 70%, right 30%, regardless of focus. The ratio is remembered
per display even with a single window. `Shift + /` and `S` selection expand a
one-slot layout using that ratio. With a temporarily vacant slot, focus can only
visit occupied slots because native master tiling has no independently focusable
empty slot.

For example, Code left and Chrome right remain a two-slot layout when `J` replaces
Code with Kitty. `S + K` then replaces Chrome with Code while focus stays on
Kitty. `N` swaps Kitty and Code while focus stays on the same screen side.

Workspace selection remains `mainMod + B` / `Shift + B`; media selection remains
`mainMod + Y` / `Shift + Y`. `mainMod + Shift + P` opens the shortcut catalog,
while `mainMod + Shift + R` opens configured commands. The existing workspace
reset explicitly restores a single terminal slot.

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
| `/` | Toggle the active display split between 70:30 and 50:50 (Hyprland) |
| `M` | Toggle the active display split between 70:30 and 50:50 (macOS) |
| `V` | Toggle a project Neovim overlay |
| `G` | Toggle a project Lazygit overlay |
| `J` | Toggle a project Kitty overlay |
| `W` | Hide all project overlays |
| `E` | Select and insert an emoji |
| `R` | Reset the current window layout (macOS only) |
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

The named Terminal and Parking workspaces remain present while empty. Their
workspace rules are scoped to the configured primary display so Waybar does not
duplicate their persistent buttons across outputs. When a display returns after
being disabled or disconnected, Hyprland restores Terminal and Parking to the
primary display and Display to the secondary display without resetting focus or
slot contents. Waybar, Hyprpaper and Hypridle are bound to
`hyprland-session.target` and supervised by `systemd --user`.

## Application shortcut forwarding

On Hyprland, `Ctrl + P/H/J/K/L` reaches the focused application unchanged. Chrome
maps it to tab search, Back, previous tab, next tab and Forward. The macOS layer
implements the same actions and translates the common Linux-shaped Chrome and
system text shortcuts to their native macOS events. VS Code remains context-owned
for commands, Monaco, Vim and its terminal, while native and webview text inputs
receive the same navigation translation. Its status is documented in
[macOS keyboard parity](docs/macos-keyboard-parity.md).

Media, volume, microphone and brightness hardware keys use their native actions.
The `Y` selection contains Spotify itself followed by Play/Pause, Next and
Previous, so Spotify no longer needs a direct App Key. The Hyprland `I` and `U`
PWA groups are not yet mirrored on macOS because their installed Chrome-PWA
bundle IDs are machine-specific and are not available in this checkout.
The actionable Hyprland shortcut catalog shows the description first and aligns
the shortcut on the right. It includes global bindings, modifier combinations,
Dot mode and hardware/media bindings; selecting a row runs that action.
Hyprland's Lua entry point is `home/.config/hypr/hyprland.lua`; architecture and
interaction notes live in [`docs/hyprland-lua.md`](docs/hyprland-lua.md). The
active macOS responsibility split is documented in
[`docs/macos-window-management.md`](docs/macos-window-management.md). Explicitly
postponed work and the macOS test procedure are tracked in [`work.md`](work.md).
