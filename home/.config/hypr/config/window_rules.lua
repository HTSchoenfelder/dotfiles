hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "project-overlays",
    match = { initial_class = "^project-overlay-.*$" },
    float = true,
    center = true,
    size = { "(monitor_w*0.95)", "(monitor_h*0.90)" },
    opacity = 0.85,
    animation = "slide bottom",
    group = "deny",
    no_shortcuts_inhibit = true,
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
