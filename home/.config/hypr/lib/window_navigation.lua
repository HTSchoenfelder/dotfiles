local compositor = require("lib.compositor")
local process = require("lib.process")
local slot_layout = require("lib.slot_layout")
local overlays = require("lib.project_overlays")
local window_navigation = {}

local function matches_application(window, application)
    return not application or window.class:lower() == application.class:lower()
end

local function monitor_position(monitor)
    local position = monitor.position or {}
    return position.x or monitor.x or 0, position.y or monitor.y or 0
end

local function focus_rank(window)
    -- Hyprland uses 0 for the most recent focus and -1 for never focused.
    return window.focus_history_id >= 0 and window.focus_history_id or math.huge
end

local function sort_by_focus(windows)
    table.sort(windows, function(first, second)
        if focus_rank(first) == focus_rank(second) then return first.address < second.address end
        return focus_rank(first) < focus_rank(second)
    end)
end

local function other_monitor()
    local current = hl.get_active_monitor()
    if not current then return end
    local monitors = hl.get_monitors()
    table.sort(monitors, function(first, second)
        local first_x, first_y = monitor_position(first)
        local second_x, second_y = monitor_position(second)
        if first_x ~= second_x then return first_x < second_x end
        return first_y < second_y
    end)
    if #monitors < 2 then return end
    local current_index = 1
    for index, monitor in ipairs(monitors) do
        if monitor == current or monitor.name == current.name then current_index = index; break end
    end
    return monitors[current_index % #monitors + 1]
end

function window_navigation.list(application, parking)
    local windows = {}
    for _, window in ipairs(hl.get_windows({ mapped = true })) do
        if slot_layout.eligible(window, parking) and matches_application(window, application) then windows[#windows + 1] = window end
    end
    sort_by_focus(windows)
    return windows
end

function window_navigation.move(window, workspace)
    if window.workspace and window.workspace.addressable_name == workspace then return end
    if window.pinned then compositor.dispatch(hl.dsp.window.pin({ window = window, action = "unset" })) end
    compositor.dispatch(hl.dsp.window.move({ window = window, workspace = workspace, follow = false }))
end

function window_navigation.new(options, picker)
    local navigation = {}
    local parking_workspace = tostring(options.parking_workspace)
    local function list(application)
        return window_navigation.list(application, parking_workspace)
    end
    local function normalize_parking()
        local parked = {}
        local group
        for _, window in ipairs(list()) do
            if window.workspace.addressable_name == parking_workspace then
                parked[#parked + 1] = window
                if window.group then group = window.group end
            end
        end
        if #parked < 2 then return end
        if not group then
            compositor.dispatch(hl.dsp.group.toggle({ window = parked[1] }))
            group = parked[1].group
        end
        if not group then return end
        for _, window in ipairs(parked) do
            if window.group ~= group then
                if window.group then window.group:remove(window) end
                group:add(window)
            end
        end
    end
    local function move(window, workspace)
        window_navigation.move(window, workspace)
        if workspace == parking_workspace then normalize_parking() end
    end
    normalize_parking()
    local slots = slot_layout.new({ parking = parking_workspace, list = list,
        move = move, state_file = options.state_file })
    local pending_launches = {}
    local opening = {}
    local requested_windows = {}
    local urgent = {}
    local initial_urgent = hl.get_urgent_window()
    if initial_urgent and initial_urgent.address then urgent[initial_urgent.address] = true end
    local stopped = false
    local latest_request
    local finish_timer

    local function selectable_windows(application)
        local windows = list(application)
        for _, window in ipairs(hl.get_windows({ mapped = true })) do
            if urgent[window.address] and window.floating and not window.hidden
                and window.workspace and not window.workspace.special
                and not overlays.is_overlay(window)
                and matches_application(window, application) then
                windows[#windows + 1] = window
            end
        end
        sort_by_focus(windows)
        return windows
    end

    local function show_urgent(window)
        if not urgent[window.address] or requested_windows[window.address]
            or not window.mapped
            or not window.workspace or window.workspace.special
            or overlays.is_overlay(window) then return end
        local workspace = hl.get_active_workspace()
        if not workspace or workspace.special then return end
        local target = slots.capture("focused", window)
        if not target then return end
        latest_request = nil
        picker.cancel()
        if window.workspace.addressable_name == workspace.addressable_name then
            if opening[window.address] and not window.floating then
                opening[window.address] = nil
                slots.opened(window, target)
            end
        else
            opening[window.address] = nil
            if window.group then window.group:remove(window) end
            if window.floating then
                window_navigation.move(window, workspace.addressable_name)
                if not window.floating then
                    compositor.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
                end
                compositor.dispatch(hl.dsp.window.center({ window = window }))
            else
                slots.place(window, target)
            end
        end
        compositor.dispatch(hl.dsp.focus({ window = window }))
    end

    local function schedule_urgent(window)
        if not urgent[window.address] then return end
        local entry = opening[window.address]
        if entry and not entry.ready then return end
        hl.timer(function()
            if not stopped then show_urgent(window) end
        end, { timeout = 1, type = "oneshot" })
    end
    if initial_urgent then schedule_urgent(initial_urgent) end

    local function request_is_current(request)
        return request == latest_request and slots.current(request.slot)
    end

    local function create_request(request_options)
        local origin = compositor.active_workspace()
        if not origin then return nil end
        request_options = request_options or {}
        local target = request_options.target or "focused"
        local slot = slots.capture(target)
        if not slot then return end
        latest_request = {
            slot = slot,
            origin_workspace = origin.addressable_name,
            workspace = origin.addressable_name,
            target = target,
            replace_layout = request_options.replace_layout == true,
        }
        return latest_request
    end

    local function select(window, request)
        if slots.place(window, request.slot) and request.replace_layout then slots.keep_only() end
        slots.schedule_refill()
    end

    local function select_window(application, windows, request, cycle_key, initial_index)
        local items = {}
        for _, window in ipairs(windows) do
            items[#items + 1] = {
                address = window.address,
                label = (window.title ~= "" and window.title or window.class)
                    .. (urgent[window.address] and " (urgent)" or ""),
                urgent = urgent[window.address] == true,
                window = window,
            }
        end
        picker.open(items, {
            cycle_key = cycle_key,
            initial_index = initial_index,
            is_current = function() return request_is_current(request) end,
            on_select = function(item)
                if item.window.mapped and matches_application(item.window, application) then
                    if item.window.floating then
                        window_navigation.move(item.window, request.workspace)
                        compositor.dispatch(hl.dsp.window.center({ window = item.window }))
                        compositor.dispatch(hl.dsp.focus({ window = item.window }))
                    else
                        select(item.window, request)
                    end
                end
            end,
        })
    end

    local function finish_launches()
        for application, launch in pairs(pending_launches) do
            local window = list(application)[1]
            if window then
                pending_launches[application] = nil
                opening[window.address] = nil
                if request_is_current(launch.request) then
                    select(window, launch.request)
                else
                    -- A late launch must not steal focus from a newer selection.
                    window_navigation.move(window, parking_workspace)
                end
            end
        end
    end

    local function schedule_launch_completion()
        if (not next(pending_launches) and not next(opening)) or finish_timer then return end
        -- window.open precedes Hyprland's initial fullscreen and focus handling.
        finish_timer = hl.timer(function()
            finish_timer = nil
            if stopped then return end
            finish_launches()
            for address, entry in pairs(opening) do
                if entry.ready and (entry.window.class ~= "" or not next(pending_launches)) then
                    opening[address] = nil
                    if entry.window.mapped then slots.opened(entry.window, entry.slot) end
                end
            end
            slots.schedule_refill()
        end, { timeout = 1, type = "oneshot" })
    end
    hl.on("window.open_early", function(window)
        if not window or not window.address then return end
        opening[window.address] = { window = window, slot = slots.capture("focused", window) }
    end)
    hl.on("window.open", function(window)
        if not window or not window.address then return end
        local entry = opening[window.address] or { window = window, slot = slots.capture("focused", window) }
        entry.ready = true
        opening[window.address] = entry
        local requested = false
        for application in pairs(pending_launches) do
            if matches_application(window, application) then requested = true; break end
        end
        if requested then
            requested_windows[window.address] = window
            hl.timer(function()
                if requested_windows[window.address] == window then
                    requested_windows[window.address] = nil
                end
            end, { timeout = 5000, type = "oneshot" })
        end
        schedule_urgent(window)
        schedule_launch_completion()
    end)
    hl.on("window.urgent", function(window)
        if stopped or not window or not window.address then return end
        urgent[window.address] = true
        schedule_urgent(window)
    end)
    hl.on("window.destroy", function(window)
        if window and window.address then
            opening[window.address] = nil
            requested_windows[window.address] = nil
            urgent[window.address] = nil
        end
    end)
    hl.on("window.active", function(window)
        if window and window.address then
            requested_windows[window.address] = nil
            urgent[window.address] = nil
        end
    end)
    for _, event in ipairs({ "window.class", "window.active" }) do
        hl.on(event, schedule_launch_completion)
    end
    hl.on("config.unload", function() stopped = true end)

    function navigation.activate(application, request_options, choose_instance)
        if picker.is_open() and choose_instance then return end
        picker.cancel()
        local request = create_request(request_options)
        if not request then return end
        local windows = choose_instance and selectable_windows(application) or list(application)
        local excluded = slots.excluded(request.slot)
        local had_windows = #windows > 0
        if excluded then
            local filtered = {}
            for _, window in ipairs(windows) do
                if window.address ~= excluded.address then filtered[#filtered + 1] = window end
            end
            windows = filtered
        end
        if #windows > 0 then
            if application then pending_launches[application] = nil end
            if choose_instance then
                select_window(application, windows, request)
            else
                select(windows[1], request)
            end
            return
        end
        if had_windows and excluded then return end
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
            if stopped then return end
            if pending_launches[application] ~= launch then return end
            pending_launches[application] = nil
            compositor.notify("No window appeared for " .. application.name .. ".")
            schedule_launch_completion()
        end, { timeout = options.launch_timeout_ms, type = "oneshot" })
        process.spawn(application.command, { workspace = request.workspace .. " silent", no_initial_focus = true })
    end

    function navigation.cycle(direction, key, request_options, application)
        if picker.is_open() then return end
        local windows = selectable_windows(application)
        if #windows == 0 then return end
        local request = create_request(request_options)
        if not request then return end
        local active_window = hl.get_active_window()
        local initial_index = compositor.next_index(windows, direction, active_window and active_window.address)
        select_window(nil, windows, request, key, initial_index)
    end

    function navigation.keep_focused_only()
        latest_request = nil
        picker.cancel()
        slots.keep_only()
    end
    function navigation.enable_two_slots()
        latest_request = nil
        picker.cancel()
        slots.enable_two()
    end
    function navigation.focus_next_slot()
        latest_request = nil
        slots.focus_next()
    end
    function navigation.rotate_positions()
        latest_request = nil
        slots.rotate()
    end
    function navigation.toggle_ratio() slots.toggle_ratio() end

    function navigation.focus_other_monitor()
        local monitor = other_monitor()
        if not monitor then return end
        latest_request = nil
        picker.cancel()
        -- Focus only the displayed workspace, never a hidden workspace from global MRU.
        local workspace = monitor.active_special_workspace or monitor.active_workspace
        if workspace then
            for _, window in ipairs(list()) do
                if window.workspace and window.workspace.addressable_name == workspace.addressable_name then
                    compositor.dispatch(hl.dsp.focus({ window = window }))
                    return
                end
            end
        end
        compositor.dispatch(hl.dsp.focus({ monitor = monitor.name }))
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
