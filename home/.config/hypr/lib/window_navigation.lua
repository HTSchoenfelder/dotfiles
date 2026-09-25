local compositor = require("lib.compositor")
local process = require("lib.process")
local window_navigation = {}

local function leave_fullscreen(window)
    if window.fullscreen ~= 0 or window.fullscreen_client ~= 0 then
        compositor.dispatch(hl.dsp.window.fullscreen_state({ window = window, internal = 0, client = 0 }))
    end
end

local function unpin(window)
    if window.pinned then
        compositor.dispatch(hl.dsp.window.pin({ window = window, action = "unset" }))
    end
end

local function matches_application(window, application)
    return not application or window.class:lower() == application.class:lower()
end

function window_navigation.list(application)
    local windows = {}
    for _, window in ipairs(hl.get_windows({ mapped = true })) do
        if matches_application(window, application) then windows[#windows + 1] = window end
    end
    local function focus_rank(window)
        -- Hyprland uses 0 for the most recent focus and -1 for never focused.
        return window.focus_history_id >= 0 and window.focus_history_id or math.huge
    end
    table.sort(windows, function(first, second)
        if focus_rank(first) == focus_rank(second) then return first.address < second.address end
        return focus_rank(first) < focus_rank(second)
    end)
    return windows
end

function window_navigation.move(window, workspace)
    if window.workspace and window.workspace.addressable_name == workspace then return end
    unpin(window)
    compositor.dispatch(hl.dsp.window.move({ window = window, workspace = workspace, follow = false }))
end

function window_navigation.show(window, destination, parking_workspace)
    if not window.mapped then return end
    -- Navigation acts on one instance, even if it previously belonged to a tab group.
    if window.group then window.group:remove(window) end
    leave_fullscreen(window)
    unpin(window)
    window_navigation.move(window, destination.workspace)
    if window.floating then
        compositor.dispatch(hl.dsp.window.float({ window = window, action = "unset" }))
    end
    if destination.add_to_stack then
        local workspace = hl.get_workspace(destination.workspace)
        if workspace and workspace.fullscreen_window then leave_fullscreen(workspace.fullscreen_window) end
        -- master.new_status = "slave" preserves existing master and stack positions.
    elseif destination.workspace ~= parking_workspace then
        for _, other in ipairs(hl.get_windows({ workspace = destination.workspace, mapped = true })) do
            if other.address ~= window.address then window_navigation.move(other, parking_workspace) end
        end
    end
    compositor.dispatch(hl.dsp.focus({ window = window }))
end

function window_navigation.rotate_positions()
    local window = hl.get_active_window()
    if not window or window.floating or not window.workspace
        or window.workspace.tiled_layout ~= "master" then return end
    -- The next layout window takes the focused slot after rollnext.
    compositor.dispatch(hl.dsp.layout("cyclenext"))
    local successor = hl.get_active_window()
    compositor.dispatch(hl.dsp.layout("rollnext"))
    if successor then compositor.dispatch(hl.dsp.focus({ window = successor })) end
end

function window_navigation.new(options, picker)
    local navigation = {}
    local parking_workspace = tostring(options.parking_workspace)
    local pending_launches = {}
    local latest_request
    local finish_timer

    local function request_is_current(request)
        return request == latest_request and compositor.workspace_is_active(request.workspace)
    end

    local function create_request(add_to_stack)
        local workspace = compositor.active_workspace()
        if not workspace then return nil end
        latest_request = { workspace = workspace.addressable_name, add_to_stack = add_to_stack }
        return latest_request
    end

    local function select_window(application, windows, request, cycle_key, initial_index)
        local items = {}
        for _, window in ipairs(windows) do
            items[#items + 1] = {
                address = window.address,
                label = window.title ~= "" and window.title or window.class,
                window = window,
            }
        end
        picker.open(items, {
            cycle_key = cycle_key,
            initial_index = initial_index,
            is_current = function() return request_is_current(request) end,
            on_stack = function() request.add_to_stack = true end,
            on_select = function(item)
                if item.window.mapped and matches_application(item.window, application) then
                    window_navigation.show(item.window, request, parking_workspace)
                end
            end,
        })
    end

    local function finish_launches()
        for application, launch in pairs(pending_launches) do
            local window = window_navigation.list(application)[1]
            if window then
                pending_launches[application] = nil
                if request_is_current(launch.request) then
                    window_navigation.show(window, launch.request, parking_workspace)
                else
                    -- A late launch must not steal focus from a newer selection.
                    window_navigation.move(window, parking_workspace)
                end
            end
        end
    end

    local function schedule_launch_completion()
        if not next(pending_launches) or finish_timer then return end
        -- window.open precedes Hyprland's initial fullscreen and focus handling.
        finish_timer = hl.timer(function()
            finish_timer = nil
            finish_launches()
        end, { timeout = 1, type = "oneshot" })
    end
    for _, event in ipairs({ "window.open", "window.class", "window.active" }) do
        hl.on(event, schedule_launch_completion)
    end

    function navigation.activate(application, add_to_stack, choose_instance)
        if picker.is_open() and choose_instance then return end
        picker.cancel()
        local request = create_request(add_to_stack)
        if not request then return end
        local windows = window_navigation.list(application)
        if #windows > 0 then
            if application then pending_launches[application] = nil end
            if choose_instance then
                select_window(application, windows, request)
            else
                window_navigation.show(windows[1], request, parking_workspace)
            end
            return
        end
        if not application then
            compositor.notify("No open windows.")
            return
        end
        if pending_launches[application] then
            pending_launches[application].request = request
            return
        end
        local launch = { request = request }
        pending_launches[application] = launch
        hl.timer(function()
            if pending_launches[application] ~= launch then return end
            pending_launches[application] = nil
            compositor.notify("No window appeared for " .. application.name .. ".")
        end, { timeout = options.launch_timeout_ms, type = "oneshot" })
        process.spawn(application.command, { workspace = request.workspace .. " silent", no_initial_focus = true })
    end

    function navigation.cycle(direction, key, add_to_stack)
        if picker.is_open() then return end
        local windows = window_navigation.list()
        if #windows == 0 then return end
        local request = create_request(add_to_stack)
        if not request then return end
        local active_window = hl.get_active_window()
        local initial_index = compositor.next_index(windows, direction, active_window and active_window.address)
        select_window(nil, windows, request, key, initial_index)
    end

    -- Other picker domains also supersede launches that have not produced a window yet.
    function navigation.invalidate_pending_focus()
        latest_request = nil
    end
    for _, event in ipairs({ "workspace.active", "workspace.special_active", "monitor.focused", "config.unload" }) do
        hl.on(event, navigation.invalidate_pending_focus)
    end

    return navigation
end

return window_navigation
