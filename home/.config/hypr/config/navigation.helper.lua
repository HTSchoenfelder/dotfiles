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

local function short_title(window, width)
    local title = window.title ~= "" and window.title or window.class
    local characters = {}
    -- Cut at UTF-8 character boundaries, and keep each title on one line.
    for character in title:gsub("%c", " "):gmatch("[^\128-\191][\128-\191]*") do
        if #characters == width then return table.concat(characters) .. "…" end
        characters[#characters + 1] = character
    end
    return table.concat(characters)
end

function M.window_list_text(windows, index, options)
    local first = math.max(1, math.min(index - math.floor(options.visible_rows / 2), #windows - options.visible_rows + 1))
    local last = math.min(#windows, first + options.visible_rows - 1)
    local lines = {}
    for i = first, last do
        if windows[i].mapped then
            lines[#lines + 1] = (i == index and "▶  " or "    ") .. short_title(windows[i], options.title_width)
        end
    end
    return table.concat(lines, "\n")
end

function M.new_window_cycle(options)
    local windows, index, workspace, overlay
    local cycle = {}

    function cycle.reset()
        if overlay then overlay:dismiss() end
        windows, index, workspace, overlay = nil, nil, nil, nil
    end

    function cycle.selection()
        local selected = windows and windows[index]
        return selected and selected.mapped and selected or nil
    end

    function cycle.next(direction)
        local current_workspace = active_workspace()
        if not current_workspace then
            cycle.reset()
            return
        end
        local current = hl.get_active_window()
        if workspace ~= current_workspace.addressable_name then cycle.reset() end

        if not windows then
            -- Only the overlay changes while cycling; the focus history stays untouched.
            windows = M.find_windows({ matches = function() return true end })
            workspace = current_workspace.addressable_name
            index = direction > 0 and 0 or 1
            for i, window in ipairs(windows) do
                if current and window.address == current.address then index = i; break end
            end
        end

        for _ = 1, #windows do
            index = (index - 1 + direction) % #windows + 1
            if windows[index].mapped then
                local text = M.window_list_text(windows, index, options)
                if overlay and overlay:is_alive() then
                    overlay:set_text(text)
                else
                    overlay = hl.notification.create({
                        text = text, timeout = 60000, icon = "none",
                        font_size = options.font_size, color = options.color,
                    })
                    overlay:pause()
                end
                return windows[index]
            end
        end
        cycle.reset()
    end

    return cycle
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

function M.picker_command(windows, prompt, token)
    local rows = {}
    for _, window in ipairs(windows) do
        -- Each window occupies exactly one row; titles are plain text, never shell/Lua code.
        rows[#rows + 1] = window.title:gsub("%c", " ")
    end
    local callback = string.format("navigation_picker_result(%q, ", token)
    local instance = assert(os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), "No Hyprland instance")
    -- Wofi runs outside the compositor. Only its zero-based numeric index crosses IPC.
    return string.format([[
choice=$(printf '%%s' %s | wofi --dmenu --insensitive --no-custom-entry --sort-order default \
    --define dmenu-print_line_num=true --define allow_markup=false --define allow_images=false --prompt %s)
status=$?
case "$choice" in ''|*[!0-9]*) choice=-1 ;; esac
if [ "$status" -ne 0 ]; then choice=-1; fi
hyprctl --instance %s eval %s"$choice)" >/dev/null
]], shell_quote(table.concat(rows, "\n") .. "\n"), shell_quote(prompt), shell_quote(instance), shell_quote(callback))
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
    local cycle = M.new_window_cycle(options.cycle_overlay)
    local cycle_request
    local launching = {}
    local latest_request
    local finish_timer
    local picker

    local function request_is_current(request)
        local workspace = active_workspace()
        return request == latest_request and workspace
            and workspace.addressable_name == request.workspace
    end

    local function cancel_cycle()
        cycle.reset()
        cycle_request = nil
    end

    local function confirm_cycle()
        local window, request = cycle.selection(), cycle_request
        cancel_cycle()
        if window and request and request_is_current(request) then
            M.show_window(window, request, parking_workspace)
        end
    end

    -- A single, token-checked IPC entry point for the asynchronous Wofi process.
    -- Config reloads replace this closure, making replies to an old picker harmless.
    _G.navigation_picker_result = function(token, index)
        if not picker or picker.token ~= token then return end
        local selection = picker
        picker = nil
        if not request_is_current(selection.request) then return end
        if type(index) ~= "number" or index < 0 or index % 1 ~= 0 then return end
        local window = selection.windows[index + 1]
        if not window or not window.mapped or not selection.app.matches(window) then return end
        M.show_window(window, selection.request, parking_workspace)
    end

    local function choose_window(app, windows, request)
        if picker then return end
        local token = tostring(request) .. ":" .. tostring(os.clock())
        local command = M.picker_command(windows, app.name .. " — Select window", token)
        picker = { token = token, app = app, windows = windows, request = request }
        hl.exec_cmd(command)
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
        cancel_cycle()
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
    hl.bind(options.mod .. " + " .. options.side_key, hl.dsp.no_op())
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
        if not workspace then cancel_cycle(); return end
        if not cycle_request or not request_is_current(cycle_request) then
            cancel_cycle()
            cycle_request = { workspace = workspace.addressable_name }
            latest_request = cycle_request
        end
        cycle_request.side = hl.is_key_down(options.side_key)
        if not cycle.next(direction) then cancel_cycle() end
    end

    hl.bind(options.mod .. " + " .. options.cycle_key, function()
        cycle_window(1)
    end, { repeating = true, description = "Cycle windows by last focus" })
    hl.bind(options.mod .. " + " .. options.cycle_reverse_mod .. " + " .. options.cycle_key, function()
        cycle_window(-1)
    end, { repeating = true, description = "Cycle windows backwards by last focus" })
    for _, mod in ipairs({ options.mod, options.mod .. " + " .. options.cycle_reverse_mod }) do
        hl.bind(mod .. " + " .. options.cycle_cancel_key, cancel_cycle,
            { description = "Cancel window selection" })
    end
    M.on_modifier_release(options.mod, confirm_cycle)
    hl.on("workspace.active", cancel_cycle)
    hl.on("workspace.special_active", cancel_cycle)
    hl.on("config.unload", cancel_cycle)
end

return M
