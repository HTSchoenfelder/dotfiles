local mocha = require("config.mocha")

local activeBorder = {
    colors = {
        mocha.rgba("green", "ee"),
        mocha.rgba("sky", "ee"),
        mocha.rgb("mauve"),
    },
}

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 5,

        border_size = 2,

        col = {
            active_border = activeBorder,
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing = false,

        layout = "master",
    },

    group = {
        col = {
            border_active = activeBorder,
            border_inactive = "rgba(595959aa)",
        },

        groupbar = {
            enabled = true,

            col = {
                active = mocha.rgba("lavender", "ee"),
                inactive = mocha.rgba("lavender", "66"),
            },

            render_titles = false,
            indicator_height = 5,
            rounding = 2,
            round_only_edges = false,
            gaps_in = 10,
            gaps_out = 5,
        },
    },

    decoration = {
        rounding = 5,

        active_opacity = 0.9,
        inactive_opacity = 0.8,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
            special = true,
        },
    },

    animations = {
        enabled = true,
    },

    master = {
        new_status = "master",
        mfact = 0.70,
    },

    misc = {
        font_family = "Agave Nerd Font",
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})

hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 },
    },
})

hl.animation({ leaf = "windows",          enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 6,  bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6,  bezier = "default", style = "slidevert" })
