mainMod = "SUPER + CTRL + ALT"

-- Application launcher
hl.bind(
    mainMod .. " + R",
    hl.dsp.exec_cmd("pkill wofi || wofi --show drun --insensitive | xargs hyprctl dispatch exec --")
)

-- Close active window (equivalent to the old killactive dispatcher)
hl.bind(
    mainMod .. " + W",
    hl.dsp.window.close()
)
