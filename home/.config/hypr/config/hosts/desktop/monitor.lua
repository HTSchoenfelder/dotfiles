local main_monitor = "HDMI-A-1"
local side_monitor = "HDMI-A-2"

hl.monitor({
    output = main_monitor,
    mode = "1920x1080",
    position = "1920x0",
    scale = 1,
    disabled = false,
})

hl.monitor({
    output = side_monitor,
    mode = "1920x1080",
    position = "0x0",
    scale = 1,
})
