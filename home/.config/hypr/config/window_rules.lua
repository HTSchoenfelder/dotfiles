hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- The upstream rule prevents empty XWayland drag surfaces from stealing focus.
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$", xwayland = true,
        float = true, fullscreen = false, pin = false,
    },
    no_focus = true,
})
