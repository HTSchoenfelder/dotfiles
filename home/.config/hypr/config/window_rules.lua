local mocha = require("config.catppuccin_mocha")

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "opaque-vlc",
    match = { class = "^vlc$" },
    opacity = "1.0 override 1.0 override 1.0 override",
})

hl.window_rule({
    name = "center-modal-dialogs",
    match = { modal = true },
    float = true,
    center = true,
})

hl.window_rule({
    name = "center-portal-dialogs",
    match = { initial_class = "^xdg-desktop-portal-gtk$" },
    float = true,
    center = true,
    max_size = { 1280, 760 },
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

hl.window_rule({
    name = "project-overlays-active-border",
    match = { initial_class = "^project-overlay-.*$", focus = true },
    border_color = mocha.rgb("sky"),
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
