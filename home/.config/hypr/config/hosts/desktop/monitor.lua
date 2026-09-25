local monitorMain = "HDMI-A-1"
local monitorSide = "HDMI-A-2"

hl.monitor({
    output = monitorMain,
    mode = "1920x1080",
    position = "1920x0",
    scale = 1,
    disabled = false,
})

hl.monitor({
    output = monitorSide,
    mode = "1920x1080",
    position = "0x0",
    scale = 1,
})
