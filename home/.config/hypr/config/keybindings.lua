local mainMod = "SUPER + CTRL + ALT"

-- Application launcher
hl.bind(
    mainMod .. " + R",
    hl.dsp.exec_cmd("pkill wofi || wofi --show drun --insensitive | xargs hyprctl dispatch exec --")
)

-- Terminal
hl.bind(
    mainMod .. " + J",
    hl.dsp.exec_cmd("export START_ZELLIJ=1 && kitty")
)
