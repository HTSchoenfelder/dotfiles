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

function M.find_windows(app)
    local windows = {}
    for _, window in ipairs(hl.get_windows({ mapped = true })) do
        if app.matches(window) then windows[#windows + 1] = window end
    end
    local function rank(window)
        -- Hyprland uses 0 for the most recent focus and -1 for never focused.
        return window.focus_history_id >= 0 and window.focus_history_id or math.huge
    end
    table.sort(windows, function(a, b)
        if rank(a) == rank(b) then return a.address < b.address end
        return rank(a) < rank(b)
    end)
    return windows
end

function M.find_window(app)
    return M.find_windows(app)[1]
end

function M.cycle_index(items, direction, current)
    if #items == 0 then return end
    current = current or hl.get_active_window()
    local index = direction > 0 and 0 or 1
    for i, item in ipairs(items) do
        if current and item.address == current.address then index = i; break end
    end
    return (index - 1 + direction) % #items + 1
end

function M.workspace_items(history)
    local items = {}
    for _, workspace in ipairs(hl.get_workspaces()) do
        if not workspace.special then
            items[#items + 1] = {
                address = workspace.addressable_name,
                title = workspace.name ~= "" and workspace.name or workspace.addressable_name,
                id = workspace.id,
            }
        end
    end
    table.sort(items, function(a, b)
        local a_rank, b_rank = history[a.address] or 0, history[b.address] or 0
        if a_rank ~= b_rank then return a_rank > b_rank end
        if a.id and b.id and a.id ~= b.id then return a.id < b.id end
        return a.address < b.address
    end)
    return items
end

function M.show_workspace(address)
    local workspace = hl.get_workspace(address)
    if workspace and not workspace.special then
        dispatch(hl.dsp.focus({ workspace = address }))
    end
end

function M.on_modifier_release(mod, callback)
    local keys = { SUPER = "Super", CTRL = "Control", CONTROL = "Control", ALT = "Alt", SHIFT = "Shift" }
    for modifier in mod:gmatch("[%w_]+") do
        local key = assert(keys[modifier:upper()], "Unsupported navigation modifier: " .. modifier)
        for _, side in ipairs({ "_L", "_R" }) do
            -- Observe releases even after a consuming shortcut, without swallowing modifier events.
            hl.bind(key .. side, callback, {
                release = true,
                ignore_mods = true,
                non_consuming = true,
                transparent = true,
            })
        end
    end
end

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

function M.picker_command(items, token, options, selected, cycle_key)
    local rows = {}
    for _, item in ipairs(items) do
        -- One plain-text row per item; duplicate titles remain distinct by index.
        local title = item.title ~= "" and item.title or item.class or item.address
        rows[#rows + 1] = title:gsub("%c", " ")
    end
    local arguments = {
        "rofi", "-dmenu", "-i", "-sync", "-no-custom", "-format", "i",
        "-no-sort", "-no-markup-rows", "-no-show-icons", "-no-auto-select", "-p", "''",
    }
    if selected then
        local mod = options.mod:gsub("%s+", ""):gsub("SUPER", "Super"):gsub("CTRL", "Control"):gsub("ALT", "Alt")
        local key = (cycle_key or options.cycle_key):lower()
        local forward = mod .. "+" .. key
        -- Account for Shift being consumed into the keysym by the US keyboard layout.
        local shifted_key = key == "comma" and "less" or key:upper()
        local backward = mod .. "+Shift+" .. key .. "," .. mod .. "+" .. shifted_key
        local accept = "Return,!Super_L,!Super_R,!Control_L,!Control_R,!Alt_L,!Alt_R,!" .. forward
            .. ",!" .. backward:gsub(",", ",!")
        arguments[#arguments + 1] = "-selected-row " .. tostring(selected - 1)
        arguments[#arguments + 1] = "-kb-row-down " .. shell_quote(forward .. ",Down")
        arguments[#arguments + 1] = "-kb-row-up " .. shell_quote(backward .. ",Up")
        arguments[#arguments + 1] = "-kb-accept-entry " .. shell_quote(accept)
        arguments[#arguments + 1] = "-kb-accept-alt '' -kb-accept-custom '' -kb-accept-custom-alt ''"
        arguments[#arguments + 1] = "-theme-str " .. shell_quote(string.format(
            "window { height: 0; } mainbox { children: [listview]; } listview { lines: %d; }", options.cycle_rows))
    end
    local instance = shell_quote(assert(os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), "No Hyprland instance"))
    local started = shell_quote(string.format("navigation_picker_started(%q, ", token))
    local result = shell_quote(string.format("navigation_picker_result(%q, ", token))
    -- Register the child's PID before exec so cancellation can also stop a pending launch.
    local process = string.format('hyprctl --instance %s eval %s"$$)" >/dev/null\nexec %s',
        instance, started, table.concat(arguments, " "))
    return string.format([[
choice=$(printf '%%s' %s | sh -c %s)
status=$?
case "$choice" in ''|*[!0-9]*) choice=-1 ;; esac
if [ "$status" -ne 0 ]; then choice=-1; fi
hyprctl --instance %s eval %s"$choice)" >/dev/null
]], shell_quote(table.concat(rows, "\n") .. "\n"), shell_quote(process), instance, result)
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

function M.cycle_workspaces(workspaces)
    if #workspaces == 0 then return end
    local current = active_workspace()
    local target = workspaces[1]
    for index, workspace in ipairs(workspaces) do
        if current and current.addressable_name == tostring(workspace) then
            target = workspaces[index % #workspaces + 1]
            break
        end
    end
    dispatch(hl.dsp.focus({ workspace = tostring(target) }))
end

function M.rotate_windows()
    local window = hl.get_active_window()
    if not window or window.floating or not window.workspace
        or window.workspace.tiled_layout ~= "master" then return end

    -- rollnext rotates [master, first slave, ...] to [first slave, ..., old master].
    -- The next layout window therefore takes the currently focused slot.
    dispatch(hl.dsp.layout("cyclenext"))
    local next_window = hl.get_active_window()
    dispatch(hl.dsp.layout("rollnext"))
    if next_window then dispatch(hl.dsp.focus({ window = next_window })) end
end

function M.setup(options)
    local parking_workspace = tostring(options.parking_workspace)
    local cycle_bindings = {}
    local launching = {}
    local latest_request
    local finish_timer
    local picker
    local workspace_history, workspace_visit = {}, 0
    local last_workspace

    local function remember_workspace(workspace)
        if not workspace or workspace.special or workspace.addressable_name == last_workspace then return end
        workspace_visit = workspace_visit + 1
        last_workspace = workspace.addressable_name
        workspace_history[last_workspace] = workspace_visit
    end
    remember_workspace(hl.get_last_workspace())
    remember_workspace(hl.get_active_workspace())

    local function request_is_current(request)
        local workspace = active_workspace()
        return request == latest_request and workspace
            and workspace.addressable_name == request.workspace
    end

    local function enable_cycle_bindings(enabled)
        for _, binding in ipairs(cycle_bindings) do binding:set_enabled(enabled) end
    end

    local function stop_process(pid)
        if type(pid) == "number" and pid > 1 and pid % 1 == 0 then
            hl.exec_cmd("kill -TERM " .. tostring(pid) .. " 2>/dev/null")
        end
    end

    local function cancel_picker()
        local previous = picker
        picker = nil
        enable_cycle_bindings(true)
        if previous then stop_process(previous.pid) end
    end

    -- Config reloads replace these closures; stale process replies cannot select a window.
    _G.navigation_picker_started = function(token, pid)
        if not picker or picker.token ~= token then stop_process(pid); return end
        picker.pid = pid
    end

    local function confirm_selection(selection, index)
        if not request_is_current(selection.request) then return end
        if type(index) ~= "number" or index < 0 or index % 1 ~= 0 then return end
        local item = selection.items[index + 1]
        if item then selection.on_select(item, selection.request) end
    end

    _G.navigation_picker_result = function(token, index)
        if not picker or picker.token ~= token then return end
        local selection = picker
        picker = nil
        enable_cycle_bindings(true)
        confirm_selection(selection, index)
    end

    local function open_picker(items, request, selected, on_select, cycle_key)
        local token = tostring(request) .. ":" .. tostring(os.clock())
        picker = { token = token, items = items, request = request, selected = selected, on_select = on_select }
        hl.exec_cmd(M.picker_command(items, token, options, selected, cycle_key))
    end

    local function choose_window(app, windows, request, selected)
        open_picker(windows, request, selected, function(window, destination)
            if window.mapped and app.matches(window) then
                M.show_window(window, destination, parking_workspace)
            end
        end)
    end

    hl.on("layer.opened", function(layer)
        if not picker or layer.namespace ~= "rofi" or layer.pid ~= picker.pid then return end
        picker.ready = true
        -- Once Rofi owns the keyboard, its native bindings handle cycling and release.
        if picker.selected then enable_cycle_bindings(false) end
    end)
    hl.on("layer.closed", function(layer)
        if picker and layer.pid == picker.pid then
            enable_cycle_bindings(true)
        end
    end)

    local function confirm_pending_cycle()
        if not picker or not picker.selected or picker.ready then return end
        -- A quick tap can finish before the launcher maps. Complete it directly.
        local selection = picker
        cancel_picker()
        confirm_selection(selection, selection.selected - 1)
    end

    local function finish_launches()
        for app, launch in pairs(launching) do
            local window = M.find_window(app)
            if window then
                launching[app] = nil
                local request = launch.request
                if request_is_current(request) then
                    M.show_window(window, request, parking_workspace)
                else
                    -- A newer app selection or workspace switch superseded this launch.
                    M.move_window(window, parking_workspace)
                end
            end
        end
    end

    local function window_ready()
        remember_workspace(hl.get_active_workspace())
        if not next(launching) or finish_timer then return end
        -- window.open fires before initial fullscreen/focus handling has finished.
        finish_timer = hl.timer(function()
            finish_timer = nil
            finish_launches()
        end, { timeout = 1, type = "oneshot" })
    end

    local function activate(app, side, choose)
        -- Keep one picker at a time; repeated presses must not stack launcher surfaces.
        if picker and choose then return end
        local workspace = active_workspace()
        if not workspace then return end
        cancel_picker()
        local request = {
            workspace = workspace.addressable_name,
            side = side,
        }
        latest_request = request

        local windows = M.find_windows(app)
        if #windows > 0 then
            launching[app] = nil
            if choose then
                choose_window(app, windows, request)
            else
                M.show_window(windows[1], request, parking_workspace)
            end
            return
        end

        if not app.command then
            notify("Navigation: No open windows.")
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
            notify("Navigation: No window appeared for " .. app.name .. ". Try again.")
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

    -- Consume these prefixes while mainMod is held; ordinary typing stays unaffected.
    hl.bind(options.mod .. " + " .. options.side_key, function()
        if picker and picker.selected and picker.request.side ~= nil then picker.request.side = true end
    end)
    hl.bind(options.mod .. " + " .. options.picker_key, hl.dsp.no_op())
    for _, app in ipairs(options.apps) do
        hl.bind(options.mod .. " + " .. app.key, function()
            activate(app, hl.is_key_down(options.side_key), hl.is_key_down(options.picker_key))
        end, { description = app.name .. ": navigate; F: add to stack; A: select window" })
    end

    local all_windows = { name = "All windows", matches = function() return true end }
    hl.bind(options.mod .. " + " .. options.all_windows_key, function()
        -- P always opens the list; holding A is equivalent to the app picker bindings.
        activate(all_windows, hl.is_key_down(options.side_key), true)
    end, { description = "Select from all windows; F: add to stack" })

    local function cycle_window(direction)
        if picker then return end
        local workspace = active_workspace()
        if not workspace then return end
        local windows = M.find_windows(all_windows)
        if #windows == 0 then return end
        local request = { workspace = workspace.addressable_name, side = hl.is_key_down(options.side_key) }
        latest_request = request
        choose_window(all_windows, windows, request, M.cycle_index(windows, direction))
    end

    local function cycle_workspace(direction)
        if picker then return end
        local workspace = active_workspace()
        if not workspace then return end
        remember_workspace(hl.get_active_workspace())
        local items = M.workspace_items(workspace_history)
        if #items == 0 then return end
        local request = { workspace = workspace.addressable_name }
        latest_request = request
        local selected = M.cycle_index(items, direction, { address = workspace.addressable_name })
        open_picker(items, request, selected, function(item)
            M.show_workspace(item.address)
        end, options.workspace_cycle_key)
    end

    local function bind_cycle(key, callback, description)
        cycle_bindings[#cycle_bindings + 1] = hl.bind(options.mod .. " + " .. key, function()
            callback(1)
        end, { description = "Cycle " .. description .. " by last focus" })
        cycle_bindings[#cycle_bindings + 1] = hl.bind(options.mod .. " + " .. options.cycle_reverse_mod .. " + " .. key, function()
            callback(-1)
        end, { description = "Cycle " .. description .. " backwards by last focus" })
    end
    bind_cycle(options.cycle_key, cycle_window, "windows")
    bind_cycle(options.workspace_cycle_key, cycle_workspace, "workspaces")
    for _, mod in ipairs({ options.mod, options.mod .. " + " .. options.cycle_reverse_mod }) do
        hl.bind(mod .. " + " .. options.cycle_cancel_key, cancel_picker,
            { description = "Cancel window selection" })
    end
    M.on_modifier_release(options.mod, confirm_pending_cycle)
    local function workspace_focused()
        cancel_picker()
        remember_workspace(hl.get_active_workspace())
    end
    hl.on("workspace.active", workspace_focused)
    hl.on("monitor.focused", workspace_focused)
    hl.on("workspace.special_active", cancel_picker)
    hl.on("config.unload", cancel_picker)
end

return M
