local M = {}

local function dispatch(action)
    local result = hl.dispatch(action)
    assert(result.ok, result.error or "Navigation action failed")
end

local function active_workspace()
    return hl.get_active_special_workspace() or hl.get_active_workspace()
end

local function on_workspace(window, workspace)
    return window.workspace and window.workspace.addressable_name == workspace
end

local function notify(message)
    hl.notification.create({ text = message, timeout = 5000, icon = "warning" })
end

local function leave_fullscreen(window)
    if window.fullscreen ~= 0 or window.fullscreen_client ~= 0 then
        dispatch(hl.dsp.window.fullscreen_state({ window = window, internal = 0, client = 0 }))
    end
end

local function unpin(window)
    if window.pinned then
        dispatch(hl.dsp.window.pin({ window = window, action = "unset" }))
    end
end

function M.by_class(class)
    return function(window) return window.class:lower() == class:lower() end
end

function M.find_window(app)
    local newest, newest_rank
    for _, window in ipairs(hl.get_windows({ mapped = true })) do
        if app.matches(window) then
            -- Hyprland uses 0 for the most recent focus and -1 for never focused.
            local rank = window.focus_history_id
            if rank < 0 then rank = math.huge end
            if not newest or rank < newest_rank then
                newest, newest_rank = window, rank
            end
        end
    end
    return newest
end

function M.move_window(window, workspace)
    if on_workspace(window, workspace) then return end
    unpin(window)
    dispatch(hl.dsp.window.move({ window = window, workspace = workspace, follow = false }))
end

function M.park_others(window, workspace, parking_workspace)
    -- Workspace 10 is the collection itself: there is nowhere else to park its windows.
    if workspace == parking_workspace then return end
    for _, other in ipairs(hl.get_windows({ workspace = workspace, mapped = true })) do
        if other.address ~= window.address then
            M.move_window(other, parking_workspace)
        end
    end
end

function M.show_window(window, request, parking_workspace)
    if not window.mapped then return end

    -- Operate on one window even when it used to belong to a tabbed group.
    if window.group then window.group:remove(window) end
    leave_fullscreen(window)
    unpin(window)
    M.move_window(window, request.workspace)
    if window.floating then
        dispatch(hl.dsp.window.float({ window = window, action = "unset" }))
    end

    if request.side then
        -- Fullscreen would hide the new stack window even though it is correctly tiled.
        local workspace = hl.get_workspace(request.workspace)
        if workspace and workspace.fullscreen_window then
            leave_fullscreen(workspace.fullscreen_window)
        end
        -- master.new_status = "slave" preserves the master and existing stack windows.
        -- An app already in the master stays there; an empty workspace gets a master.
    else
        M.park_others(window, request.workspace, parking_workspace)
    end
    dispatch(hl.dsp.focus({ window = window }))
end

function M.setup(options)
    local parking_workspace = tostring(options.parking_workspace)
    local launching = {}
    local latest_request
    local finish_timer

    local function finish_launches()
        for app, launch in pairs(launching) do
            local window = M.find_window(app)
            if window then
                launching[app] = nil
                local request = launch.request
                local workspace = active_workspace()
                if request == latest_request and workspace
                    and workspace.addressable_name == request.workspace then
                    M.show_window(window, request, parking_workspace)
                else
                    -- A newer app selection or workspace switch superseded this launch.
                    M.move_window(window, parking_workspace)
                end
            end
        end
    end

    local function window_ready()
        if not next(launching) or finish_timer then return end
        -- window.open fires before initial fullscreen/focus handling has finished.
        finish_timer = hl.timer(function()
            finish_timer = nil
            finish_launches()
        end, { timeout = 1, type = "oneshot" })
    end

    local function activate(app, side)
        local workspace = active_workspace()
        if not workspace then return end
        local request = { workspace = workspace.addressable_name, side = side }
        latest_request = request

        local window = M.find_window(app)
        if window then
            launching[app] = nil
            M.show_window(window, request, parking_workspace)
            return
        end

        if launching[app] then
            -- Repeated presses update the destination/mode without spawning again.
            launching[app].request = request
            return
        end

        local launch = { request = request }
        launching[app] = launch
        hl.timer(function()
            if launching[app] ~= launch then return end
            launching[app] = nil
            notify("Navigation: Kein Fenster für " .. app.name .. " erschienen. Erneut versuchen.")
        end, { timeout = options.launch_timeout_ms, type = "oneshot" })

        hl.exec_cmd(app.command, {
            workspace = request.workspace .. " silent",
            no_initial_focus = true,
        })
    end

    hl.on("window.open", window_ready)
    hl.on("window.class", window_ready)
    -- Some single-instance applications restore a hidden window instead of opening one.
    hl.on("window.active", window_ready)

    for _, app in ipairs(options.apps) do
        hl.bind(options.mod .. " + " .. app.key, function() activate(app, false) end,
            { description = app.name .. ": fokussieren und andere Fenster wegräumen" })
        hl.bind(options.mod .. " + SHIFT + " .. app.key, function() activate(app, true) end,
            { description = app.name .. ": im rechten Stack ergänzen" })
    end
end

return M
