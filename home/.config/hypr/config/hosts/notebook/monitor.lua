local monitor_configuration = require("lib.monitor_configuration")

local notebook_display = "eDP-1"

monitor_configuration.set_workspace_roles({ primary = notebook_display })

monitor_configuration.apply({
    output = notebook_display,
    mode = "3840x2400",
    position = "1920x0",
    scale = 2.133333,
})

-- Optional external displays from the previous configuration:
-- monitor_configuration.apply({
--     output = "DP-6",
--     mode = "1920x1080",
--     position = "0x0",
--     scale = 1,
-- })
--
-- monitor_configuration.apply({
--     output = "DP-4",
--     mode = "1920x1080",
--     position = "0x0",
--     scale = 1,
-- })
