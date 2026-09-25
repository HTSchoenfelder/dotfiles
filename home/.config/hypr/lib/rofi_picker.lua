local compositor = require("lib.compositor")
local process = require("lib.process")
local rofi_picker = {}

local modifier_names = { SUPER = "Super", CTRL = "Control", CONTROL = "Control", ALT = "Alt", SHIFT = "Shift" }

local function modifier_keys(modifier)
    local names = {}
    for name in modifier:gmatch("[%w_]+") do
        names[#names + 1] = assert(modifier_names[name:upper()], "Unsupported modifier: " .. name)
    end
    return names
end

local function cycle_arguments(options, selection)
    local names = modifier_keys(options.modifier)
    local modifier = table.concat(names, "+")
    local key = selection.cycle_key:lower()
    local forward = modifier .. "+" .. key
    -- Shift may be consumed into the keysym by the US keyboard layout.
    local shifted_key = key == "comma" and "less" or key:upper()
    local backward = modifier .. "+Shift+" .. key .. "," .. modifier .. "+" .. shifted_key
    local accept = { "Return", "!" .. forward, "!" .. backward:gsub(",", ",!") }
    for _, name in ipairs(names) do
        accept[#accept + 1] = "!" .. name .. "_L"
        accept[#accept + 1] = "!" .. name .. "_R"
    end
    return {
        "-selected-row", tostring(selection.initial_index - 1),
        "-kb-row-down", forward .. ",Down", "-kb-row-up", backward .. ",Up",
        "-kb-accept-entry", table.concat(accept, ","),
        "-kb-accept-alt", "", "-kb-accept-custom", "", "-kb-accept-custom-alt", "",
        "-theme-str", string.format(
            "window { height: 0; } mainbox { children: [listview]; } listview { lines: %d; }", options.rows),
    }
end

function rofi_picker.new(options)
    local picker = {}
    local active_selection
    local latest_selection
    local cycle_bindings = {}

    local function enable_cycle_bindings(enabled)
        for _, binding in ipairs(cycle_bindings) do binding:set_enabled(enabled) end
    end

    local function detach_selection()
        local selection = active_selection
        active_selection = nil
        enable_cycle_bindings(true)
        if selection then os.remove(selection.rows_path) end
        return selection
    end

    function picker.is_open()
        return active_selection ~= nil
    end

    function picker.cancel()
        latest_selection = nil
        local selection = detach_selection()
        if selection then process.terminate(selection.pid) end
    end

    local function confirm(selection, index)
        if not selection or selection ~= latest_selection then return end
        latest_selection = nil
        if not compositor.workspace_is_active(selection.workspace) then return end
        if selection.is_current and not selection.is_current() then return end
        if type(index) ~= "number" or index < 0 or index % 1 ~= 0 then return end
        local item = selection.items[index + 1]
        if item then selection.on_select(item) end
    end

    -- Reload replaces these closures. Late replies cannot confirm a newer selection.
    _G.rofi_picker_started = function(token, pid)
        if not active_selection or active_selection.token ~= token then
            process.terminate(pid)
            return
        end
        active_selection.pid = pid
    end
    _G.rofi_picker_selected = function(token, index)
        if active_selection and active_selection.token == token then
            -- The provider returns before Rofi closes. Wait for focus to leave its layer.
            active_selection.result = index
        end
    end

    hl.on("layer.opened", function(layer)
        local selection = active_selection
        if not selection or layer.namespace ~= "rofi" or layer.pid ~= selection.pid then return end
        selection.ready = true
        if selection.cycle_key then enable_cycle_bindings(false) end
    end)
    hl.on("layer.closed", function(layer)
        if not active_selection or layer.pid ~= active_selection.pid then return end
        local selection = detach_selection()
        if selection.result ~= nil then
            -- Layer teardown restores keyboard focus after emitting this event.
            hl.timer(function() confirm(selection, selection.result) end, { timeout = 1, type = "oneshot" })
        else
            latest_selection = nil
        end
    end)

    function picker.open(items, selection)
        if active_selection or #items == 0 then return false end
        local workspace = compositor.active_workspace()
        if not workspace then return false end
        -- Lua uses mkstemp on Linux: only this user can read the temporary rows.
        local rows_path = os.tmpname()
        local rows, error_message = io.open(rows_path, "w")
        if not rows then
            os.remove(rows_path)
            compositor.notify("Cannot open launcher: " .. tostring(error_message))
            return false
        end
        for _, item in ipairs(items) do
            -- Plain text only; duplicate labels remain distinct through numeric row metadata.
            rows:write(item.label:gsub("%c", " "), "\n")
        end
        rows:close()
        selection.items = items
        selection.rows_path = rows_path
        selection.token = rows_path .. ":" .. tostring(selection)
        selection.workspace = workspace.addressable_name
        active_selection = selection
        latest_selection = selection
        local provider = process.command({ "lua", options.provider, selection.token, rows_path })
        local arguments = { "rofi", "-show", "selection", "-modes", "selection:" .. provider,
            "-no-sort", "-no-show-icons", "-no-auto-select" }
        if selection.cycle_key then
            for _, argument in ipairs(cycle_arguments(options, selection)) do
                arguments[#arguments + 1] = argument
            end
        end
        process.spawn(arguments)
        hl.timer(function()
            if active_selection == selection and not selection.ready then
                picker.cancel()
                compositor.notify("Rofi did not open.")
            end
        end, { timeout = 3000, type = "oneshot" })
        return true
    end

    function picker.add_to_stack()
        if active_selection and active_selection.on_stack then active_selection.on_stack() end
    end

    function picker.bind_cycle(key, callback, description)
        for _, direction in ipairs({ 1, -1 }) do
            local modifier = options.modifier .. (direction < 0 and " + SHIFT" or "")
            cycle_bindings[#cycle_bindings + 1] = hl.bind(modifier .. " + " .. key, function()
                callback(direction)
            end, { description = description .. (direction < 0 and " backwards" or "") })
        end
    end

    local function confirm_before_mapping()
        local selection = active_selection
        if not selection or not selection.cycle_key or selection.ready then return end
        detach_selection()
        process.terminate(selection.pid)
        confirm(selection, selection.initial_index - 1)
    end
    for _, name in ipairs(modifier_keys(options.modifier)) do
        for _, side in ipairs({ "_L", "_R" }) do
            hl.bind(name .. side, confirm_before_mapping, {
                release = true, ignore_mods = true, non_consuming = true, transparent = true,
            })
        end
    end
    for _, modifier in ipairs({ options.modifier, options.modifier .. " + SHIFT" }) do
        hl.bind(modifier .. " + Escape", picker.cancel, { description = "Cancel selection" })
    end
    for _, event in ipairs({ "workspace.active", "workspace.special_active", "monitor.focused", "config.unload" }) do
        hl.on(event, picker.cancel)
    end

    function picker.toggle_app_launcher()
        if picker.is_open() then picker.cancel(); return end
        local found_launcher = false
        for _, layer in ipairs(hl.get_layers()) do
            if layer.namespace == "rofi" then
                found_launcher = true
                process.terminate(layer.pid)
            end
        end
        if not found_launcher then process.spawn({ "rofi", "-show", "drun" }) end
    end

    return picker
end

return rofi_picker
