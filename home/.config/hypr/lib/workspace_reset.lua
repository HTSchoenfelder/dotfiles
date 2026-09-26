local compositor = require("lib.compositor")
local monitor_configuration = require("lib.monitor_configuration")
local workspace_reset = {}

local function enabled_monitor(configured_name, fallback_index)
    local monitors = hl.get_monitors()
    for _, monitor in ipairs(monitors) do
        if configured_name and configured_name ~= "" and monitor.name == configured_name then
            return monitor.name
        end
    end
    return monitors[fallback_index or 1] and monitors[fallback_index or 1].name
end

function workspace_reset.new(options)
    local reset = {}
    local terminal_workspace = tostring(options.workspaces.terminal)
    local display_workspace = tostring(options.workspaces.display)
    local parking_workspace = tostring(options.workspaces.parking)

    local function ensure_workspace(address)
        if not hl.get_workspace(address) then
            compositor.dispatch(hl.dsp.focus({ workspace = address }))
        end
    end

    local function move_workspace(address, monitor)
        if monitor then
            compositor.dispatch(hl.dsp.workspace.move({ workspace = address, monitor = monitor }))
        end
    end

    function reset.run()
        local roles = monitor_configuration.workspace_roles()
        local primary_monitor = enabled_monitor(roles.primary, 1)
        local secondary_monitor = enabled_monitor(roles.secondary, 2) or primary_monitor
        if not primary_monitor then
            compositor.notify("No enabled display is available.")
            return
        end

        ensure_workspace(terminal_workspace)
        ensure_workspace(display_workspace)
        ensure_workspace(parking_workspace)
        move_workspace(terminal_workspace, primary_monitor)
        move_workspace(display_workspace, secondary_monitor)
        move_workspace(parking_workspace, primary_monitor)

        compositor.dispatch(hl.dsp.focus({ workspace = terminal_workspace }))
        options.activate_terminal()
    end

    return reset
end

return workspace_reset
