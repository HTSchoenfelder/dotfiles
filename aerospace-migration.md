# AeroSpace migration implementation brief

## Instruction to the implementing agent

Implement this specification completely on the target macOS machine. This file is
the user's explicit approval of the Hammerspoon plus AeroSpace architecture and of
the migration described below. Do not stop after analysis or return only a plan.
Inspect the real repository and machine state first, then implement, validate and
iterate until the acceptance criteria are satisfied or a concrete macOS limitation
is demonstrated.

This brief is self-contained. Conversation history is not required. Supporting
architecture documentation exists in `docs/macos-window-management.md`, but this
file is authoritative for the migration task.

Do not commit, push, reset, rebase or discard changes unless the user separately
asks for that operation. Preserve every unrelated local modification. In
particular, inspect `git status` and the complete diff before editing; the working
tree may already contain documentation changes and unrelated editor settings.

Use English for code, comments, identifiers, notifications, chooser text and
shortcut descriptions. Communicate with the user in German. This is a personal
power-user repository: keep UI surfaces compact and omit onboarding text, keyboard
hints and explanatory labels.

## Approved decisions

The following architectural decisions are settled and must not be reopened unless
runtime evidence on the Mac proves one of them infeasible:

1. Hyprland is the behavioral source of truth for the cross-platform workflow.
2. Hammerspoon remains installed and is the only global keyboard-input and
   interaction layer on macOS.
3. AeroSpace becomes the window-management backend.
4. AeroSpace does not own regular workflow keybindings. Remove or disable its
   legacy direct bindings so they cannot conflict with Hammerspoon.
5. Hammerspoon owns all global shortcuts, held modifiers, key-release handling,
   Comma Selection, Dot Mode, chooser UI, application intentions, MIDI/hardware
   integration and master-layout orchestration.
6. AeroSpace owns the window tree, tiling geometry, workspaces, monitor assignment,
   focus, move, swap, resize and floating/tiling state.
7. Hammerspoon calls AeroSpace asynchronously. Do not use blocking process I/O from
   hotkey callbacks.
8. `hs.chooser` is the shared selection UI. Do not add Raycast, Alfred, Sol, Ueli or
   another launcher.
9. AeroSpace uses its supported TOML configuration. Do not generate TOML from Lua.
10. Do not use native Mission Control Spaces as the workflow model. AeroSpace
    workspaces represent Terminal, Display and Parking.
11. Install AeroSpace through the official Homebrew cask and declare it in the
    repository's macOS `Brewfile`. Do not install a second AeroSpace package through
    Nix. Starting AeroSpace at login is intended.
12. Preserve RØDECaster support in Hammerspoon; AeroSpace has no MIDI
    responsibility.

## Product goal

The result must make the macOS workflow feel like the current Hyprland workflow so
the same muscle memory works on both systems. Match the meaning, key sequence,
modifier combinations, selection lifecycle and visible outcome. The implementation
primitives do not need to match.

Optimize for Henrik's workflow rather than for general users. Reliable behavior,
low latency and deterministic focus are more important than adding generic options.
Avoid configuration screens and interactive setup inside the workflow.

## Required preflight

Before editing:

1. Read the repository `AGENTS.md` and obey it.
2. Run `git status --short` and inspect all existing diffs. Never overwrite
   unrelated changes.
3. Read the complete current configurations, including imports:
   - `home/.hammerspoon/`
   - `home/.aerospace.toml`
   - `home/.config/hypr/hyprland.lua`
   - `home/.config/hypr/config/`
   - relevant `home/.config/hypr/lib/` modules
   - `setup/macos/`
   - `readme.md`
   - `docs/macos-window-management.md`
4. Inspect the target machine rather than assuming paths or versions:
   - macOS version and architecture
   - Hammerspoon version
   - AeroSpace installation/version, if already present
   - `aerospace config --config-path`
   - Homebrew prefix
   - connected monitor names and arrangement
   - Accessibility permission state
   - RØDECaster MIDI device name and availability
5. Consult the current official documentation before using an API:
   - <https://nikitabobko.github.io/AeroSpace/guide>
   - <https://nikitabobko.github.io/AeroSpace/commands>
   - <https://www.hammerspoon.org/docs/>
   - <https://www.hammerspoon.org/docs/hs.chooser.html>
   - <https://www.hammerspoon.org/docs/hs.task.html>
   - <https://www.hammerspoon.org/docs/hs.window.filter.html>
   - <https://www.hammerspoon.org/docs/hs.midi.html>
6. Record a concise baseline of currently working behavior before changing it.

If Accessibility permission or another macOS consent dialog blocks runtime
validation, complete all code and configuration work that does not depend on it.
Then ask the user for the single concrete action needed and continue validation
after it is granted.

## Existing repository state

The current macOS implementation uses Hammerspoon alone for navigation and direct
frame placement. Relevant files include:

- `home/.hammerspoon/init.lua`
- `home/.hammerspoon/config.lua`
- `home/.hammerspoon/apps.lua`
- `home/.hammerspoon/navigation.lua`
- `home/.hammerspoon/modules/application_navigation.lua`
- `home/.hammerspoon/modules/window_navigation.lua`
- `home/.hammerspoon/modules/display_layout.lua`
- `home/.hammerspoon/modules/window_chooser.lua`
- `home/.hammerspoon/modules/comma_selection.lua`
- `home/.hammerspoon/modules/held_keys.lua`
- `home/.hammerspoon/launcher.lua`
- `home/.hammerspoon/shortcuts.lua`
- `home/.hammerspoon/windows.lua`
- `home/.hammerspoon/midi.lua`
- `home/.hammerspoon/remapping.lua`
- `home/.hammerspoon/shortcut_catalog.lua`

The current application launcher uses the Seal Spoon. Window activation and layout
use `hs.window:setFrame`, minimization/unminimization and Hammerspoon screen objects.
Existing tests in `tests/hammerspoon_*_test.lua` cover parts of that behavior.

`home/.aerospace.toml` already exists, but it was only an experiment. Its options,
bindings, modes and comments are disposable and must not be treated as requirements
or a migration baseline. Replace its contents wholesale with the backend-only
target configuration if that remains the chosen repository path. Do not create a
second active AeroSpace config. Verify the path with
`aerospace config --config-path` after installation.

`setup/macos/Brewfile` currently declares Hammerspoon but not AeroSpace. The macOS
setup uses nix-darwin plus Homebrew casks, but `setup-macos.sh` does not currently
run `brew bundle`. Its hard-coded flake selector also differs from the `macbook`
configuration exported by `setup/macos/flake.nix`. Repair this setup path as part
of package integration, use the requested configuration argument consistently and
make the repository's Brewfile effective without adding a second package owner.

## Final responsibility model

```text
Hyprland
`- behavioral source of truth

macOS
|- Hammerspoon
|  |- all global shortcuts
|  |- held-key and modifier-release state
|  |- application intentions and launch lifecycle
|  |- MRU history
|  |- hs.chooser UI
|  |- Comma Selection and Dot Mode
|  |- launcher, text insertion and command selection
|  |- MIDI and RØDECaster integration
|  `- master/stack orchestration decisions
|
`- AeroSpace
   |- window and container tree
   |- tiling/floating geometry
   |- workspace state
   |- monitor assignment
   `- focus, move, swap and resize execution
```

Hammerspoon may observe windows and focus to maintain interaction state, but it must
not continue as a second geometry engine. After migration, normal managed-window
placement must not call `hs.window:setFrame`, `moveToScreen`, `maximize` or similar
geometry APIs. `hs.canvas` remains valid for small overlays. A deliberately floating
project overlay may still be sized through AeroSpace commands or, only when
AeroSpace cannot express the required floating frame, through one clearly isolated
Hammerspoon adapter with the exception documented.

## Performance contract

The interaction must remain suitable for repeated keyboard use:

- Use `hs.task` or another verified asynchronous mechanism for AeroSpace CLI calls.
- Retain active task objects until completion so Lua garbage collection cannot
  cancel them.
- Pass argument arrays. Never build commands by interpolating window titles or
  other untrusted strings into a shell.
- Parse machine-readable JSON from `aerospace list-* --json`; do not parse human
  columns.
- Resolve the AeroSpace executable once from configured/candidate Homebrew paths.
- Query chooser candidates once when a chooser session opens.
- Cycle selection locally in Hammerspoon.
- Send only the accepted mutation/focus command when the modifier is released.
- Combine ordered mutations into one supported `aerospace eval` request when that
  is safer and faster than multiple client calls.
- Pass explicit window IDs for chooser-derived actions.
- Use monotonically increasing request IDs or equivalent cancellation tokens so a
  slow query or late application launch cannot override a newer user action.
- Coalesce or reject stale repeated requests; do not build an unbounded task queue.
- Keep logging useful for debugging without showing routine user notifications.

Measure the important paths on the Mac. Add temporary timing logs if useful, then
remove or reduce them before completion. Direct AeroSpace hotkeys are not the
default performance workaround; first fix unnecessary queries, shell startup,
blocking calls or request backlogs.

## AeroSpace client boundary

Create a focused Hammerspoon adapter for AeroSpace. Exact filenames may follow the
repository style, but the boundary must provide these capabilities:

- execute one command asynchronously
- execute an ordered expression asynchronously
- query windows as structured records
- query monitors and visible/focused workspaces
- focus a specific window ID
- move a specific window ID to a workspace
- move a window/workspace between monitors where required
- apply `layout`, `join-with`, `flatten-workspace-tree`, `balance-sizes`, `swap` or
  equivalent current commands
- expose actionable errors to callers
- distinguish unavailable CLI, invalid configuration, command failure and stale
  response

The rest of the Hammerspoon code must depend on this adapter rather than scattering
raw `hs.task` and command construction throughout navigation modules. Keep pure
selection, sorting and layout-planning logic separate where it improves testing.

Do not mirror the complete AeroSpace tree as mutable Hammerspoon state. Query the
backend when a high-level operation begins and keep only short-lived snapshots plus
MRU metadata.

## Workspace model

Use these stable logical workspaces:

| Logical role | AeroSpace workspace | UI name |
| --- | --- | --- |
| Terminal Workspace | `1` | `` |
| Display Workspace | `2` | `󰍹` |
| Parking Workspace | `10` | `󰮍` |

The Terminal Workspace belongs on the primary display. The Display Workspace
belongs on the secondary display when one is connected. Parking holds windows that
should disappear from the active workflow. Do not use native macOS minimization as
the normal Parking implementation once AeroSpace is active.

Use monitor-pattern fallbacks rather than a transient numeric ID: workspace 1 and
Parking target `main`; workspace 2 prefers `secondary` and falls back to `main`
when no second display exists. Validate the exact pattern list against the installed
AeroSpace version.

The logical workspaces must remain addressable even while empty. With two displays,
workspaces 1 and 2 should normally be visible on their assigned displays. With one
display, workspace navigation must still provide both without errors. Do not
hard-code a transient numeric monitor ID; derive monitor roles from current
AeroSpace monitor information or a documented host-specific pattern.

`mainMod + H` switches/focuses between workspaces 1 and 2. When both are visible on
different displays, this naturally changes focused display. On one display, it
switches the visible workspace.

Workspace Comma Selection uses `mainMod + G` forward and
`mainMod + Shift + G` backward, is ordered by most recent focus and accepts on
`mainMod` release. The current Hyprland implementation lists every non-special
workspace, so Parking participates once it exists. Preserve that behavior. `H`
continues to address only workspaces 1 and 2.

## Layout model

AeroSpace has no semantic master layout. Represent the desired geometry with its
container tree:

```text
h_tiles
|- master window
`- v_tiles
   |- stack window 1
   `- stack window 2
```

Required visual behavior:

- One visible tiled window occupies the usable workspace area.
- Two visible tiled windows split the workspace left/right at 1:1.
- With three or more visible tiled windows, one master occupies the left half and
  the remaining windows form a vertical stack in the right half.
- Existing stack windows remain in their relative order when another app is added
  to the stack.
- Dialogs and intentional overlays must not corrupt the tiled tree.
- Focus remains on the intended window after every tree mutation.

The 1:1 ratio is an explicit macOS requirement. Hyprland currently uses
`mfact = 0.70`, so its master/stack ratio is 70/30. Preserve the shared interaction
semantics and treat this ratio as a documented platform difference; do not change
the macOS target to 70/30 merely to copy that implementation detail.

Keep AeroSpace normalization enabled unless a reproducible tree operation requires
a documented exception. Prefer `join-with` over legacy `split`. Use
`flatten-workspace-tree` only when rebuilding is actually required; do not visibly
rebuild the entire workspace after every focus change.

Implement one layout-orchestration module that converts user intent into ordered
AeroSpace operations. It must handle windows closing or appearing during a request,
single-window workspaces, a missing secondary display and an already-correct tree.

## Application definitions

Keep application configuration declarative and use bundle IDs as stable identity:

| Key | Application | Bundle ID |
| --- | --- | --- |
| `J` | Kitty with Zellij | `net.kovidgoyal.kitty` |
| `K` | Visual Studio Code | `com.microsoft.VSCode` |
| `L` | Google Chrome | `com.google.Chrome` |
| `I` | Google Chat | Installed Chrome PWA bundle ID; verify on target |
| `;` | Obsidian | `md.obsidian` |
| `O` | KeePassXC | `org.keepassxc.keepassxc` |
| `U` | Spotify | `com.spotify.client` |

`mainMod` on macOS is `Option + Control + Command`.

Google Chat is a Chrome PWA rather than the normal Chrome window. The current
Hammerspoon fallback launches it by the installed application name `Google Chat`.
Inspect the PWA wrapper under `~/Applications/Chrome Apps.localized/`, record its
real bundle ID and use that identity after migration. Do not match it as generic
`com.google.Chrome`, which would mix Chat with ordinary browser windows.

Launching Kitty through the application shortcut must preserve the intended Zellij
startup (`START_ZELLIJ=1` in the current shell configuration). Verify the correct
macOS launch mechanism rather than assuming a GUI application inherits a terminal
environment. Existing application-specific new-window shortcuts may be reused when
they reliably create another window.

## Application navigation behavior

For every application shortcut:

1. Capture the originating focused workspace and request generation.
2. Query matching managed windows by bundle ID.
3. Without `A`, choose the most recently focused matching window.
4. With `A`, always open the instance chooser, even when exactly one instance
   exists.
5. If no instance exists, launch the application, wait asynchronously for an
   AeroSpace-visible window and then apply the original request.
6. A later user action cancels the focus intent of an older launch. A late window
   may be parked, but it must never steal focus from the newer action.
7. Bring the selected window to the destination workspace before arranging it.
8. End with deterministic focus on the selected window unless the specified action
   intentionally preserves a focused slot instead.

Default application activation acts on the currently active workspace: move the
selected window there, move the other managed tiled windows from that workspace to
Parking and show the selected window full-size. When Parking itself is deliberately
focused, do not attempt to park its other windows into itself.

Holding `F` changes the action to add-to-stack: preserve the existing master and
stack windows, bring the selected application into the right stack and focus it.
Existing right-side windows must stay in place relative to each other.

The modifiers are combinable. `A + F + app key` first chooses the instance and then
adds that selected instance to the stack.

## Window history and selection

AeroSpace does not provide the complete Hyprland focus-history model required by
this workflow. Maintain MRU metadata in Hammerspoon, preferably from a verified
`hs.window.filter` focus subscription. Seed it from the best available ordered
window list on reload. Join records by the stable macOS/AeroSpace window ID and
validate that both APIs report compatible IDs on the target machine.

Exclude unusable windows such as menu items, transient nonstandard AX elements and
windows intentionally ignored/floated by policy. Do not exclude normal windows only
because they currently live in Parking.

`mainMod + P` opens an `hs.chooser` containing all managed windows ordered by recent
focus. Show only the information needed to distinguish the window, normally
`Application — Title`; do not show the current workspace. Enter confirms the
choice. Holding `F` applies the normal add-to-stack behavior to the selected window.

`mainMod + ,` starts or advances Comma Selection forward.
`mainMod + Shift + ,` starts or advances it backward. The chooser is visible while
cycling and accepts the highlighted window when the base `mainMod` combination is
released. It must not require Enter. `A + ,` restricts candidates to instances of
the currently focused application. Holding `F` applies add-to-stack to the accepted
window.

The chooser must also open when there is only one candidate where an explicit
selection was requested. Escape cancels without changing focus or layout. A screen,
workspace or newer selection change invalidates stale chooser actions.

## Direct navigation shortcuts

Implement these through Hammerspoon and AeroSpace:

| Shortcut | Behavior |
| --- | --- |
| `mainMod + M` | Focus the next tiled window on the active workspace |
| `mainMod + N` | Rotate window positions while the currently focused visual slot retains focus |
| `mainMod + H` | Focus/switch between Terminal and Display Workspaces |
| `mainMod + W` | Close the focused window |
| `mainMod + G` | Workspace Comma Selection forward |
| `mainMod + Shift + G` | Workspace Comma Selection backward |

For `N`, distinguish window identity from visual slot. The windows rotate, and the
window that arrives at the previously focused position receives focus, matching the
current Hyprland behavior. Test one, two, three and more windows.

Media Comma Selection on `mainMod + Y` was deferred from this migration and was
implemented later as an independent Hammerspoon feature.

## Application launcher and shared chooser UI

Replace the Seal-based launcher with a compact `hs.chooser` application launcher on
`mainMod + R`. Do not retain Seal solely for application enumeration. Prefer a
current native Hammerspoon API such as Spotlight metadata when it can enumerate
installed `.app` bundles reliably; otherwise use one isolated asynchronous indexer.

Required launcher behavior:

- fast fuzzy search through installed applications
- application name and icon where reliably available
- launch or focus the selected application
- no placeholder instructions, descriptions or help rows
- no duplicate copies of the same bundle unless they are meaningfully distinct
- refresh after application installations without requiring a permanent stale
  cache
- center on the active screen where the API permits it
- use the same compact visual configuration as window, emoji, snippet, command and
  shortcut choosers

Centralize common `hs.chooser` construction and lifecycle behavior without hiding
domain-specific selection logic behind a generic framework. `mainMod + Shift + R`
continues to show the searchable shortcut catalog.

## Dot Mode

`mainMod + .` enters Dot Mode. Hammerspoon owns the mode. Show a small persistent
`dot mode` status notice near the top-right of the active screen and remove it when
the mode exits. The notice contains no instructions. The next recognized action,
Escape or an unbound key exits the mode before the selected tool takes focus.

Implement the Hyprland actions where macOS has a reliable equivalent:

| Key | Required action |
| --- | --- |
| `Q` | Capture an interactive region |
| `A` | Capture the focused window |
| `Z` | Capture the focused monitor |
| `B` | Choose a connected display with enabled/disabled status and toggle it when a reliable supported implementation exists |
| `G` | Toggle the current project's LazyVim/Neovim overlay |
| `Shift + G` | Toggle the current project's Lazygit overlay |
| `J` | Toggle the current project's Kitty terminal overlay |
| `E` | Choose and insert an emoji |
| `R` | Choose and execute a configured macOS command |
| `T` | Choose and insert a snippet |
| `Escape` | Leave Dot Mode |

Use macOS `screencapture` or a verified native API for screenshots. Match the
normal macOS screenshot destination semantics unless the current machine has an
explicitly configured destination.

Reuse the existing trusted emoji and snippet data from
`home/.config/hypr/launcher-data/` rather than duplicating it. Text insertion must
return focus to the originating window, support Unicode and multiline snippets and
avoid permanently replacing the user's clipboard. Never evaluate selected text as
a shell command.

The existing `execute.txt` contains Linux-specific commands. Do not expose commands
that cannot work on macOS. Provide a clearly platform-specific macOS command source
or filtering layer. It must at least support a native action that restores the
three workspaces to their initial state with Terminal Workspace focused and Kitty
with Zellij on it. Any shell command comes only from trusted configuration and must
be executed without interpolating chooser output.

Project overlays are floating, reusable windows associated with a project path.
Reuse an existing overlay per project/tool, hide it on a dedicated nonvisible
workspace when toggled off and keep only the selected overlay visible. Derive the
project from the focused VS Code window or an existing overlay. Validate the actual
macOS VS Code title/path signal before relying on the Linux title format. If macOS
does not expose a trustworthy project path, finish the remaining implementation and
document this one demonstrated limitation instead of guessing directories.

The current macOS Dot Mode additionally contains display movement and maximize
actions. Preserve them through AeroSpace if they remain useful and do not conflict
with the Hyprland keys; mark them as macOS-specific in the shortcut catalog. Remove
their direct Hammerspoon geometry implementation.

For display enable/disable, do not introduce an unmaintained private-API utility
silently. First verify whether AeroSpace or supported macOS APIs can perform the
operation. If an additional open-source tool is genuinely required, explain the
specific gap and obtain user approval before installing that extra dependency.

## RØDECaster and input remapping

Preserve the current RØDECaster Pro II behavior:

- listen for MIDI `controlChange`
- channel `0`
- controller number `27`
- pressed value `1`
- send the corresponding press/release sequence from
  `mainMod + Shift + M`
- debounce duplicate events
- show/hide the mute status overlay

Keep the MIDI object alive and handle the device being absent at Hammerspoon reload
without crashing unrelated configuration. If touched, convert existing German code
comments/log text to English and use `hs.midi.deviceCallback` where needed for safe
reconnection. Do not move MIDI handling into AeroSpace.

Preserve the existing terminal, Chrome, VS Code and general Ctrl-to-macOS shortcut
remapping behavior unless a verified conflict with the new global shortcuts
requires a narrow correction.

## AeroSpace TOML requirements

Replace the disposable test contents of `home/.aerospace.toml` rather than adding a
competing config. Validate every new option against the installed AeroSpace
version. The finished file should include:

- `config-version = 2`
- `persistent-workspaces = ["1", "2", "10"]`
- `start-at-login = true`
- enabled container normalizations unless a tested exception is documented
- horizontal tile root defaults
- deliberate gaps matching the desired compact desktop
- automatic unhide behavior if it remains compatible with app navigation
- workspace/monitor policy for workspaces 1, 2 and 10, including the single-display
  fallback
- window-detection rules only where backed by observed bundle IDs, roles or titles
- an empty/minimal required main binding table with no normal workflow shortcuts
- English comments only

Remove legacy direct shortcuts, service modes and example/comment blocks that no
longer describe the active design. The TOML should read as a concise backend policy,
not as a copy of the upstream example config.

Use `aerospace reload-config` and configuration introspection to prove that the
active process reads the repository-managed file. A successful TOML parse alone is
insufficient if AeroSpace is loading a different path.

## Package and startup integration

Install AeroSpace with the official Homebrew cask/tap syntax current at
implementation time (`nikitabobko/tap/aerospace` at the time this brief was
written). Update `setup/macos/Brewfile` and any existing setup step necessary to
make the repository declaration effective. Homebrew is the sole package owner for
AeroSpace; do not also add `pkgs.aerospace` or another Nix package declaration.

Do not add Hammerspoon or AeroSpace startup through multiple mechanisms. Retain the
established Hammerspoon startup path and use AeroSpace's declared login startup
mechanism unless the current repository already has one authoritative launchd
owner. Verify there is exactly one running AeroSpace process after reload/login.

Do not silently change the macOS “Displays have separate Spaces” setting. Inspect
it and the current multi-monitor behavior. If changing it is required to solve a
demonstrated same-application/multi-monitor focus problem, present that exact
trade-off to the user after the implementation is otherwise ready.

## Suggested module structure

Adapt names to the existing repository where useful, but preserve these boundaries:

```text
home/.hammerspoon/
|- init.lua                         composition only
|- config.lua                       user-facing constants
|- apps.lua                         declarative application definitions
|- navigation.lua                   binding composition
|- modules/
|  |- aerospace_client.lua          async CLI and JSON boundary
|  |- window_repository.lua         backend records and AX enrichment
|  |- window_history.lua            MRU state
|  |- layout_orchestrator.lua       Parking and master/stack intent
|  |- workspace_navigation.lua      workspace focus and MRU selection
|  |- application_navigation.lua    launch/focus/instance lifecycle
|  |- window_navigation.lua         high-level window actions
|  |- chooser.lua                   shared compact chooser styling/lifecycle
|  |- comma_selection.lua           cycle and release-to-accept sessions
|  |- dot_mode.lua                  modal lifecycle and status notice
|  `- ...                           focused launcher/text modules
|- midi.lua                         RØDECaster integration
|- remapping.lua                    application-specific input remapping
`- shortcut_catalog.lua             generated searchable reference
```

Do not create every suggested file mechanically. Merge responsibilities when a
smaller design remains clear, but do not put backend calls, layout policy, chooser
state and application launch polling into one module.

Remove modules made obsolete by AeroSpace only after all callers and tests have
migrated. Typical candidates include direct frame calculation and the old
`windows.lua` geometry actions. Search the repository before deletion.

## Implementation sequence

Complete these phases in order, validating each before continuing. Do not stop and
ask for approval between phases unless a real permission or product decision not
settled in this brief blocks further work.

### Phase 1: backend and declarative setup

1. Integrate the AeroSpace package.
2. Replace the disposable test TOML contents with the minimal backend policy.
3. Confirm the active config path and reload behavior.
4. Implement and test the asynchronous AeroSpace client.
5. Add clear failure behavior when AeroSpace is unavailable.

### Phase 2: window and workspace primitives

1. Implement structured window/monitor/workspace queries.
2. Implement MRU tracking and ID reconciliation.
3. Implement focus, move, close, monitor and workspace actions.
4. Implement the 1:1 and master/right-stack orchestration.
5. Implement Terminal, Display and Parking semantics.
6. Migrate `M`, `N`, `H` and `W`.

### Phase 3: application navigation

1. Migrate application matching and launch lifecycle.
2. Implement default Parking behavior.
3. Implement `F`, `A`, and combined modifiers.
4. Ensure late launches and rapid requests cannot steal focus.

### Phase 4: chooser workflows

1. Centralize compact `hs.chooser` presentation.
2. Migrate `P` and application instance selection.
3. Migrate window Comma Selection with release acceptance.
4. Add workspace Comma Selection.
5. Replace Seal with the application launcher.
6. Keep the shortcut catalog synchronized.

### Phase 5: Dot Mode and device integrations

1. Replace the old window-action modal with the unified Dot Mode.
2. Add screenshots, text launchers and applicable commands.
3. Port project overlays where macOS exposes a reliable project identity.
4. Preserve/migrate macOS-specific window actions through AeroSpace.
5. Validate RØDECaster and input remapping behavior.

### Phase 6: cleanup and documentation

1. Remove obsolete direct-geometry code and unused Seal dependencies.
2. Remove duplicate or conflicting shortcut registrations.
3. Update all tests and add focused tests for new pure logic.
4. Update `readme.md`, `docs/macos-window-management.md` and any affected setup
   documentation to describe the implemented state rather than the plan.
5. Update `AGENTS.md` only if the final responsibility boundary differs for a
   demonstrated reason.
6. Inspect the complete diff for accidental changes.

## Automated validation

Add meaningful tests around behavior rather than tests that merely reproduce the
implementation. Mock the AeroSpace adapter and Hammerspoon APIs at boundaries.
Cover at least:

- JSON record decoding and invalid output
- executable-not-found and nonzero-exit handling
- stale async request rejection
- MRU ordering and stable tie-breaking
- application bundle matching
- explicit instance selection with one and multiple windows
- late application launch behavior
- default Parking plan
- add-to-stack plan and order preservation
- single-display fallback
- one-, two-, three- and multi-window layout planning
- focus-slot-preserving rotation
- chooser cancellation and modifier-release acceptance
- Comma Selection forward/backward and application filtering
- shortcut catalog ordering
- parsing Unicode emoji and multiline snippets

Run all existing Hammerspoon tests and the new tests with the repository's Lua
interpreter. Validate syntax for every Lua file. Run `git diff --check`. Use the
installed AeroSpace validation/reload commands for TOML. Do not claim that mocks
prove macOS focus or Accessibility behavior.

## Required macOS runtime validation

Exercise the actual configuration in an interactive graphical session. Test both a
single-monitor setup and the normal two-monitor setup when available.

### Backend and startup

- AeroSpace starts once at login and uses the repository-managed TOML.
- Hammerspoon reloads without console errors.
- Both applications have required Accessibility access.
- There are no duplicate hotkey registrations.
- Holding common application shortcuts does not leak characters into the focused
  application.

### Layout and workspaces

- Empty workspace, one window, two windows and three windows produce the expected
  geometry.
- Closing master and stack windows leaves a valid normalized layout.
- Terminal and Display remain addressable while empty.
- Parking removes windows from the active workspace and they remain recoverable.
- `H` behaves correctly with one and two monitors.
- Disconnecting/reconnecting the secondary display does not strand windows.
- `M` cycles only the intended workspace windows.
- `N` rotates positions and keeps focus on the visual slot.

### Application navigation

For every configured application, test:

- not running
- running with one window
- running with several windows
- a window in Parking
- a window on the other display
- default activation
- `F`
- `A`, including one instance
- `A + F`
- rapid requests for two different applications
- a slow/late launch followed by another action

### Choosers

- `P` is MRU ordered and omits workspace text.
- Window Comma Selection cycles in both directions and accepts on modifier release.
- `A + ,` contains only the focused application's windows.
- Escape cancels without changing layout.
- Workspace selection uses the same release lifecycle.
- The application launcher finds installed apps and launches/focuses them.
- Choosers appear on the intended screen and contain no instructional labels.

### Dot Mode and hardware

- The status notice appears top-right and disappears on every exit path.
- Region, focused-window and focused-monitor screenshots work.
- Emoji and snippets return to and insert into the originating app.
- Clipboard content is restored after insertion.
- Applicable configured commands run; Linux-only commands are absent.
- Project overlays toggle predictably or the exact platform limitation is recorded.
- The physical RØDECaster button and keyboard shortcut remain synchronized as well
  as the available device protocol permits.
- Connecting the RØDECaster after Hammerspoon starts does not require a full config
  failure/recovery.

### Performance and resilience

- Repeated `M`, `N`, `H` and Comma Selection input remains responsive.
- No unbounded `hs.task` accumulation occurs.
- A failed AeroSpace command produces a concise actionable error and leaves the
  current layout intact.
- Reloading Hammerspoon during an open chooser cleans up event taps and tasks.
- Restarting AeroSpace does not require restarting the Mac; Hammerspoon recovers or
  reports the backend as unavailable and recovers on the next action.

## Acceptance criteria

The migration is complete only when all of the following are true:

1. Hammerspoon is the sole owner of workflow shortcuts.
2. AeroSpace contains no conflicting regular shortcuts.
3. Managed window geometry and workspace mutations go through AeroSpace.
4. The Terminal, Display and Parking model works on the real Mac.
5. The required application navigation and combinable modifiers work.
6. Window and workspace Comma Selection accept on modifier release.
7. `hs.chooser` replaces Seal for the application launcher and serves the shared
   selection UI.
8. Existing Ctrl remapping and RØDECaster behavior have no regressions.
9. The configuration survives Hammerspoon and AeroSpace reloads.
10. Automated tests pass, TOML is loaded successfully and the runtime checklist has
    been executed as far as connected hardware permits.
11. Direct Hammerspoon geometry code made obsolete by AeroSpace is removed.
12. Documentation and shortcut catalogs describe the actual final behavior.
13. No unrelated working-tree changes were overwritten or included accidentally.

If a macOS limitation prevents one item, provide evidence from the actual machine,
finish all independent work, document the narrow divergence and explain its impact
on muscle memory. Do not replace a failed item with speculative code.

## Completion report

When finished, report in German:

- the final responsibility split
- files added, changed and removed
- the observable workflow now implemented
- automated validation commands and results
- macOS runtime checks and results
- measured or observed performance of repeated navigation
- remaining demonstrated platform limitations
- the complete uncommitted Git status/diff summary

Do not create a commit unless the user explicitly requests it after reviewing the
implementation.
