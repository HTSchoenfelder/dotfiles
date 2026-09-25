mainMod = "SUPER + CTRL + ALT"

-- Application launcher
hl.bind(
    mainMod .. " + R",
    hl.dsp.exec_cmd("pkill -x rofi || rofi -show drun")
)

hl.layer_rule({ match = { namespace = "rofi" }, no_anim = true })

-- Close active window (equivalent to the old killactive dispatcher)
hl.bind(
    mainMod .. " + W",
    hl.dsp.window.close()
)
