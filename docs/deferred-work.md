# Deferred Work

This file records fixes and refactorings that may be useful later. Entries are
documentation only. Do not implement, investigate further, or include them in
another change unless Henrik explicitly requests the specific item.

## Project editor overlay leaks `G` input

`dot mode` followed by `J` toggles the project terminal overlay reliably. With
the LazyVim overlay, the first `dot mode` + `G` opens it, but the same sequence
does not reliably hide it again. The `G` input can reach the previously focused
client instead; this was observed as two literal `g` characters in a chat input.

Adding `dont_inhibit` to the dot-mode bindings and
`no_shortcuts_inhibit = true` to the project-overlay window rule did not resolve
the behavior. A later fix should trace the real key press and release sequence,
submap transitions, focus changes, and possible event forwarding before changing
the binding model again.

## Keep configured workspaces permanent

The configured workspaces should remain available while empty. Workspace 1
(``) currently disappears after its final window leaves it, for example after
manually switching to Parking. Configure the primary and Parking workspace rules
as persistent using the current Hyprland Lua API so their names and navigation
targets remain stable.
