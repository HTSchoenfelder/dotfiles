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
            return true
        end
        return false
    end

    local function move_workspace(address, monitor)
        local workspace = hl.get_workspace(address)
        if monitor and workspace and (not workspace.monitor or workspace.monitor.name ~= monitor) then
            compositor.dispatch(hl.dsp.workspace.move({ workspace = address, monitor = monitor }))
        end
    end

    function reset.restore_roles()
        local roles = monitor_configuration.workspace_roles()
        local primary_monitor = enabled_monitor(roles.primary, 1)
        local secondary_monitor = enabled_monitor(roles.secondary, 2) or primary_monitor
        if not primary_monitor then
            compositor.notify("No enabled display is available.")
            return
        end

        local active_window = hl.get_active_window()
        local active_workspace = hl.get_active_workspace()
        local focus_changed = ensure_workspace(terminal_workspace)
        focus_changed = ensure_workspace(display_workspace) or focus_changed
        focus_changed = ensure_workspace(parking_workspace) or focus_changed
        move_workspace(terminal_workspace, primary_monitor)
        move_workspace(display_workspace, secondary_monitor)
        move_workspace(parking_workspace, primary_monitor)

        if focus_changed then
            if active_window then
                compositor.dispatch(hl.dsp.focus({ window = active_window }))
            elseif active_workspace then
                compositor.dispatch(hl.dsp.focus({ workspace = active_workspace.addressable_name }))
            end
        end
    end

    function reset.run()
        reset.restore_roles()
        compositor.dispatch(hl.dsp.focus({ workspace = terminal_workspace }))
        options.activate_terminal()
    end

    return reset
end

return workspace_reset
