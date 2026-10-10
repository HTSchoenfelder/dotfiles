local compositor = require("lib.compositor")
local process = require("lib.process")
local slot_layout = require("lib.slot_layout")
local window_navigation = {}

local function matches_application(window, application)
    return not application or window.class:lower() == application.class:lower()
end

local function monitor_position(monitor)
    local position = monitor.position or {}
    return position.x or monitor.x or 0, position.y or monitor.y or 0
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

function window_navigation.list(application)
    local windows = {}
    for _, window in ipairs(hl.get_windows({ mapped = true })) do
        if slot_layout.eligible(window) and matches_application(window, application) then windows[#windows + 1] = window end
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
    if window.pinned then compositor.dispatch(hl.dsp.window.pin({ window = window, action = "unset" })) end
    compositor.dispatch(hl.dsp.window.move({ window = window, workspace = workspace, follow = false }))
end

function window_navigation.new(options, picker)
    local navigation = {}
    local parking_workspace = tostring(options.parking_workspace)
    local slots = slot_layout.new({ parking = parking_workspace, list = window_navigation.list,
        move = window_navigation.move, state_file = options.state_file })
    local pending_launches = {}
    local opening = {}
    local stopped = false
    local latest_request
    local finish_timer

    local function request_is_current(request)
        return request == latest_request and slots.current(request.slot)
    end

    local function create_request(request_options)
        local origin = compositor.active_workspace()
        if not origin then return nil end
        request_options = request_options or {}
        local slot = slots.capture(request_options.other_slot)
        if not slot then return end
        latest_request = {
            slot = slot,
            origin_workspace = origin.addressable_name,
            workspace = origin.addressable_name,
            other_slot = request_options.other_slot == true,
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
                label = window.title ~= "" and window.title or window.class,
                window = window,
            }
        end
        picker.open(items, {
            cycle_key = cycle_key,
            initial_index = initial_index,
            is_current = function() return request_is_current(request) end,
            on_select = function(item)
                if item.window.mapped and matches_application(item.window, application) then
                    select(item.window, request)
                end
            end,
        })
    end

    local function finish_launches()
        for application, launch in pairs(pending_launches) do
            local window = window_navigation.list(application)[1]
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
        opening[window.address] = { window = window, slot = slots.capture(false, window) }
    end)
    hl.on("window.open", function(window)
        if not window or not window.address then return end
        local entry = opening[window.address] or { window = window, slot = slots.capture(false, window) }
        entry.ready = true
        opening[window.address] = entry
        schedule_launch_completion()
    end)
    hl.on("window.destroy", function(window)
        if window and window.address then opening[window.address] = nil end
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
        local windows = window_navigation.list(application)
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
        local windows = window_navigation.list(application)
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
            for _, window in ipairs(window_navigation.list()) do
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
