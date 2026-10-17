local workspaces = { terminal = 1, display = 2, parking = 10 }
local roles = require("lib.monitor_configuration").workspace_roles()

local function configured_monitor(role)
    return role and role ~= "" and role or nil
end

hl.config({
    general = { layout = "master" },
    master = { orientation = "left", mfact = 0.70, new_status = "slave" },
    group = { group_on_movetoworkspace = false },
})

hl.workspace_rule({
    workspace = "1", monitor = configured_monitor(roles.primary), layout = "master",
    default_name = "", persistent = true,
})
hl.workspace_rule({ workspace = "2", monitor = configured_monitor(roles.secondary), default_name = "󰍹" })
hl.workspace_rule({
    workspace = tostring(workspaces.parking), monitor = configured_monitor(roles.primary),
    default_name = "󰮍", persistent = true,
})

return workspaces
