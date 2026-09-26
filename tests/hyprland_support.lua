local support = {}

function support.session()
    local session = { windows = {}, spaces = {}, bindings = {}, events = {}, timers = {}, commands = {}, notices = {}, held = {}, submap = "reset" }
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
        }
        return session.spaces[address]
    end
    session.current = session.space(1)
    session.space(2)
    session.space(10)

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
        bind = function(key, callback)
            key = defining_submap == "reset" and key or defining_submap .. ":" .. key
            assert(not session.bindings[key], "Duplicate binding: " .. key)
            local binding = { callback = callback, enabled = true }
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
        notification = { create = function(notice) table.insert(session.notices, notice) end },
        dsp = {
            no_op = dispatcher("noop"), layout = dispatcher("layout"), focus = dispatcher("focus"), submap = dispatcher("submap"),
            window = {
                close = dispatcher("close"), move = dispatcher("move"), float = dispatcher("float"),
                fullscreen_state = dispatcher("fullscreen"), pin = dispatcher("pin"),
            },
        },
        dispatch = function(action)
            local arguments = action.arguments
            local window = type(arguments) == "table" and arguments.window
            if action.kind == "submap" then session.submap = arguments
            elseif action.kind == "move" then
                if window.fail_move then return { ok = false, error = "Move failed" } end
                assert(arguments.follow == false)
                window.workspace = session.space(arguments.workspace)
            elseif action.kind == "focus" then
                if window then session.focus(window)
                else
                    session.current = session.space(arguments.workspace)
                    session.emit("workspace.active", session.current)
                end
            elseif action.kind == "float" then window.floating = false
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
    require("config.keybindings")
    return session
end

return support
