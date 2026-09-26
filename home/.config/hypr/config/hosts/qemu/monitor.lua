local monitor_configuration = require("lib.monitor_configuration")

monitor_configuration.set_workspace_roles({ primary = "" })

monitor_configuration.apply({
    output = "",
    mode = "1920x1080",
    position = "auto",
    scale = 1,
})
