mainMod = "SUPER + CTRL + ALT"

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

-- Close active window (equivalent to the old killactive dispatcher)
hl.bind(
    mainMod .. " + W",
    hl.dsp.window.close()
)

-- Focus Chrome if a window exists, otherwise launch it
hl.bind(
    mainMod .. " + L",
    hl.dsp.exec_cmd([[if hyprctl clients -j | jq -e 'any(.[]; .class == "google-chrome")' >/dev/null; then
        hyprctl dispatch 'hl.dsp.focus({ window = "class:^(google-chrome)$" })'
    else
        google-chrome-stable
    fi]])
)
