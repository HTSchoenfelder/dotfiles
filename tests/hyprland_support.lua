local support = {}

function support.session()
    local session = { windows = {}, spaces = {}, monitors = {}, monitor_rules = {}, workspace_moves = {}, bindings = {}, events = {}, timers = {}, commands = {}, shortcuts = {}, notices = {}, held = {}, submap = "reset" }
    local defining_submap = "reset"
    local process = require("lib.process")
    local original_spawn = process.spawn
    process.spawn = function(arguments, rules)
        session.commands[#session.commands + 1] = { arguments = arguments, rules = rules }
    end

    function session.space(address)
        address = tostring(address)
        session.spaces[address] = session.spaces[address] or {
            addressable_name = address, name = address, id = tonumber(address),
            special = address:match("^special:") ~= nil, tiled_layout = "master",
            monitor = { width = 1920, height = 1080 },
        }
        return session.spaces[address]
    end
    session.current = session.space(1)
    session.space(2)
    session.space(10)
    session.monitors = {
        { name = "HDMI-A-1", enabled = true, focused = true },
        { name = "HDMI-A-2", enabled = false, focused = false },
    }

    function session.emit(event, ...)
        for _, callback in ipairs(session.events[event] or {}) do callback(...) end
    end
    function session.flush(delay)
        local pending = session.timers
        session.timers = {}
        for _, timer in ipairs(pending) do
            if timer.delay <= (delay or 1) then timer.callback()
            else session.timers[#session.timers + 1] = timer end
        end
    end
    function session.add(class, workspace, rank)
        local window = {
            address = tostring(#session.windows + 1), class = class, title = class,
            workspace = session.space(workspace), focus_history_id = rank or 0,
            mapped = true, fullscreen = 0, fullscreen_client = 0, floating = false, pinned = false,
        }
        session.windows[#session.windows + 1] = window
        return window
    end
    function session.retile_on_next_center(window)
        session.retile_before_center = window
    end
    function session.focus(window)
        session.focused = window
        if window then session.current = window.workspace end
        session.emit("window.active", window)
    end
    function session.press(key)
        local binding_key = session.submap == "reset" and key or session.submap .. ":" .. key
        local binding = session.bindings[binding_key] or session.bindings[session.submap .. ":catchall"]
        assert(binding, "Missing binding: " .. key)
        if not binding.enabled then return end
        if type(binding.callback) == "function" then binding.callback()
        else hl.dispatch(binding.callback) end
    end
    function session.picker_request()
        for index = #session.commands, 1, -1 do
            local arguments = session.commands[index].arguments
            if arguments[1] == "rofi" and arguments[3] == "selection" then
                local provider = {}
                for value in arguments[5]:gmatch("'([^']*)'") do provider[#provider + 1] = value end
                return { token = provider[3], path = provider[4], arguments = arguments }
            end
        end
    end
    function session.map_picker(pid)
        local request = assert(session.picker_request())
        rofi_picker_started(request.token, pid or 5000)
        session.emit("layer.opened", { namespace = "rofi", pid = pid or 5000 })
        return request
    end
    function session.choose(index)
        local request = session.map_picker()
        rofi_picker_selected(request.token, index)
        session.emit("layer.closed", { namespace = "rofi", pid = 5000 })
        session.flush()
    end
    function session.close()
        session.emit("config.unload")
        process.spawn = original_spawn
    end

    local function dispatcher(kind)
        return function(arguments) return { kind = kind, arguments = arguments } end
    end
    hl = {
        config = function() end, workspace_rule = function() end, window_rule = function() end, layer_rule = function() end,
        get_layers = function() return {} end,
        get_active_workspace = function() return session.current end,
        get_active_special_workspace = function() return nil end,
        get_active_window = function() return session.focused end,
        get_monitors = function(options)
            local monitors = {}
            for _, monitor in ipairs(session.monitors) do
                if options and options.all or monitor.enabled then monitors[#monitors + 1] = monitor end
            end
            return monitors
        end,
        get_last_workspace = function() return nil end,
        get_workspace = function(address) return session.spaces[tostring(address)] end,
        get_workspaces = function()
            local spaces = {}
            for _, space in pairs(session.spaces) do spaces[#spaces + 1] = space end
            return spaces
        end,
        get_windows = function(filter)
            local windows = {}
            for _, window in ipairs(session.windows) do
                if (not filter.mapped or window.mapped)
                    and (not filter.workspace or window.workspace.addressable_name == filter.workspace) then
                    windows[#windows + 1] = window
                end
            end
            return windows
        end,
        is_key_down = function(key) return session.held[key] or false end,
        define_submap = function(name, callback)
            local previous = defining_submap
            defining_submap = name
            callback()
            defining_submap = previous
        end,
        get_current_submap = function() return session.submap end,
        bind = function(key, callback, options)
            key = defining_submap == "reset" and key or defining_submap .. ":" .. key
            assert(not session.bindings[key], "Duplicate binding: " .. key)
            local binding = { callback = callback, enabled = true, options = options or {} }
            function binding:set_enabled(enabled) self.enabled = enabled end
            session.bindings[key] = binding
            return binding
        end,
        on = function(event, callback)
            session.events[event] = session.events[event] or {}
            table.insert(session.events[event], callback)
        end,
        timer = function(callback, options)
            local timer = { callback = callback, delay = options.timeout }
            session.timers[#session.timers + 1] = timer
            return timer
        end,
        monitor = function(specification)
            session.monitor_rules[#session.monitor_rules + 1] = specification
            for _, monitor in ipairs(session.monitors) do
                if monitor.name == specification.output then monitor.enabled = not specification.disabled end
            end
        end,
        notification = { create = function(options)
            local notice = { options = options, alive = true, paused = false }
            function notice:dismiss() self.alive = false end
            function notice:pause() self.paused = true end
            table.insert(session.notices, notice)
            return notice
        end },
        dsp = {
            send_shortcut = dispatcher("shortcut"), no_op = dispatcher("noop"), layout = dispatcher("layout"), focus = dispatcher("focus"), submap = dispatcher("submap"),
            window = {
                close = dispatcher("close"), move = dispatcher("move"), float = dispatcher("float"),
                resize = dispatcher("resize"), center = dispatcher("center"), deny_from_group = dispatcher("deny_group"),
                fullscreen_state = dispatcher("fullscreen"), pin = dispatcher("pin"),
            },
            workspace = { move = dispatcher("workspace_move") },
        },
        dispatch = function(action)
            local arguments = action.arguments
            local window = type(arguments) == "table" and arguments.window
            if action.kind == "shortcut" then table.insert(session.shortcuts, arguments)
            elseif action.kind == "submap" then
                session.submap = arguments == "reset" and "reset" or arguments
                session.emit("keybinds.submap", arguments == "reset" and "" or arguments)
            elseif action.kind == "move" then
                if window.fail_move then return { ok = false, error = "Move failed" } end
                assert(arguments.follow == false)
                window.workspace = session.space(arguments.workspace)
                if window.retile_on_move then window.floating = false end
            elseif action.kind == "focus" then
                if window then session.focus(window)
                else
                    session.current = session.space(arguments.workspace)
                    session.emit("workspace.active", session.current)
                end
            elseif action.kind == "float" then window.floating = arguments.action == "set"
            elseif action.kind == "resize" then window.size = { arguments.x, arguments.y }
            elseif action.kind == "center" then
                if session.retile_before_center == window then
                    session.retile_before_center = nil
                    window.floating = false
                end
                if not window.floating then return { ok = false, error = "No floating window found" } end
                window.centered = true
            elseif action.kind == "deny_group" then session.group_denied = true
            elseif action.kind == "workspace_move" then
                local workspace = session.space(arguments.workspace)
                for _, monitor in ipairs(session.monitors) do
                    if monitor.name == arguments.monitor then workspace.monitor = monitor end
                end
                session.workspace_moves[#session.workspace_moves + 1] = arguments
            elseif action.kind == "pin" then window.pinned = false
            elseif action.kind == "fullscreen" then
                window.fullscreen, window.fullscreen_client = 0, 0
                window.workspace.fullscreen_window = nil
            elseif action.kind == "layout" then
                local order = session.layout_order or {}
                if arguments == "cyclenext" then
                    for index, item in ipairs(order) do
                        if item == session.focused then session.focused = order[index % #order + 1]; break end
                    end
                elseif arguments == "rollnext" and #order > 1 then
                    order[#order + 1] = table.remove(order, 1)
                end
            end
            return { ok = true }
        end,
    }
    package.loaded["config.workspaces"] = nil
    package.loaded["config.keybindings"] = nil
    package.loaded["config.hardware_keys"] = nil
    require("lib.monitor_configuration").set_workspace_roles({})
    require("config.keybindings")
    require("config.hardware_keys")
    return session
end

return support
