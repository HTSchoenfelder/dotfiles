local workspaces = { primary = { 1, 2 }, parking = 10 }

hl.config({
    general = { layout = "master" },
    master = { orientation = "left", mfact = 0.70, new_status = "slave" },
    group = { group_on_movetoworkspace = false },
})

hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.workspace_rule({ workspace = "1", layout = "master", default_name = "" })
hl.workspace_rule({ workspace = "2", default_name = "󰍹" })
hl.workspace_rule({ workspace = tostring(workspaces.parking), default_name = "󰮍" })

return workspaces
