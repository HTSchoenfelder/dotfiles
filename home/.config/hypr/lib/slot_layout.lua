local compositor = require("lib.compositor")
local overlays = require("lib.project_overlays")
local slot_layout = {}

-- Floating utility windows (including native dialogs) and overlays are not slots.
function slot_layout.eligible(window)
    return window and window.mapped and not window.floating and not window.hidden
        and not overlays.is_overlay(window) and window.workspace and not window.workspace.special
end

local function same(a, b)
    return a and b and a.address == b.address
end

local function prepare(window)
    if window.group then window.group:remove(window) end
    if window.fullscreen ~= 0 or window.fullscreen_client ~= 0 then
        compositor.dispatch(hl.dsp.window.fullscreen_state({ window = window, internal = 0, client = 0 }))
    end
    if window.pinned then compositor.dispatch(hl.dsp.window.pin({ window = window, action = "unset" })) end
end

function slot_layout.new(options)
    local slots = {}
    local states, ratios = {}, {}
    local busy, stopped = false, false
    local pending_refill
    local closing = {}
    local focus_epoch = 0

    -- Session-scoped, data-only checkpoint: preserve vacancies across config reloads.
    if options.state_file then
        local file = io.open(options.state_file, "r")
        if file then
            local windows = {}
            for _, window in ipairs(options.list()) do windows[window.address] = window end
            for line in file:lines() do
                local kind, key, a, b, left, right = line:match("^([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
                if kind == "slots" and (a == "1" or a == "2") and (b == "1" or b == "2") then
                    states[key] = { workspace = key, wanted = tonumber(a), focused = tonumber(b), revision = 0,
                        windows = { windows[left], windows[right] } }
                elseif kind == "ratio" and (a == "0.5" or a == "0.7") then
                    ratios[key] = tonumber(a)
                end
            end
            file:close()
            os.remove(options.state_file)
        end
    end

    local function managed(workspace)
        return workspace and not workspace.special and workspace.addressable_name ~= options.parking
    end

    local function members(workspace, except)
        local result = {}
        for _, window in ipairs(options.list()) do
            if slot_layout.eligible(window) and not same(window, except) and not closing[window.address]
                and window.workspace.addressable_name == workspace.addressable_name then
                result[#result + 1] = window
            end
        end
        table.sort(result, function(a, b)
            local am, bm = a.layout and a.layout.is_master, b.layout and b.layout.is_master
            if am ~= bm then return am == true end
            local ax, bx = (a.at or {}).x or 0, (b.at or {}).x or 0
            if ax ~= bx then return ax < bx end
            return a.address < b.address
        end)
        return result
    end

    local function alive(window, state)
        return slot_layout.eligible(window) and not closing[window.address]
            and window.workspace.addressable_name == state.workspace
    end

    local function state_for(workspace, except)
        if not managed(workspace) then return end
        local state = states[workspace.addressable_name]
        if not state then
            local windows = members(workspace, except)
            local second = windows[2]
            local active = hl.get_active_window()
            for index = 3, #windows do
                if same(windows[index], active) then second = active end
            end
            state = { workspace = workspace.addressable_name, wanted = math.max(1, math.min(2, #windows)),
                windows = { windows[1], second }, focused = same(second, active) and 2 or 1, revision = 0 }
            states[state.workspace] = state
        end
        for index = 1, 2 do
            if state.windows[index] and not alive(state.windows[index], state) then state.windows[index] = nil end
        end
        return state
    end

    local function locate(window)
        if not window or not window.workspace then return end
        local state = state_for(window.workspace)
        if state then
            for index = 1, 2 do
                if same(state.windows[index], window) then return state, index end
            end
        end
    end

    local function focus(window)
        if window and window.mapped then compositor.dispatch(hl.dsp.focus({ window = window })) end
    end

    local function swap(a, b)
        prepare(a)
        prepare(b)
        compositor.dispatch(hl.dsp.window.swap({ window = a, target = b }))
    end

    local function order(state)
        local left, right = state.windows[1], state.windows[2]
        if left and right and left.layout and not left.layout.is_master then swap(left, right) end
    end

    local function ratio_for(state)
        local workspace = hl.get_workspace(state.workspace)
        local monitor = workspace and workspace.monitor
        local key = monitor and monitor.name or state.workspace
        if not ratios[key] then
            local master = state.windows[1] or state.windows[2]
            ratios[key] = master and master.layout and master.layout.perc_master or 0.70
        end
        return key, ratios[key]
    end

    local function apply_ratio(state)
        if not compositor.workspace_is_active(state.workspace) then return end
        local active = hl.get_active_window()
        if not slot_layout.eligible(active) then return end
        local _, ratio = ratio_for(state)
        compositor.dispatch(hl.dsp.layout("mfact exact " .. tostring(ratio)))
    end

    local function transaction(callback)
        local previous = busy
        busy = true
        local ok, err = xpcall(callback, debug.traceback)
        busy = previous
        if not ok then error(err) end
    end

    function slots.capture(other, except)
        local workspace = hl.get_active_workspace()
        local state = state_for(workspace, except)
        if not state then return end
        local active = hl.get_active_window()
        for index = 1, 2 do
            if same(state.windows[index], active) then state.focused = index end
        end
        return { state = state, index = other and (3 - state.focused) or state.focused,
            other = other == true, focused = state.focused, revision = state.revision, origin = state.workspace }
    end

    function slots.current(request)
        return request and request.state.revision == request.revision
            and request.state.focused == request.focused
            and compositor.workspace_is_active(request.origin)
    end

    function slots.excluded(request)
        return request and request.other and request.state.windows[request.state.focused] or nil
    end

    local function parking_candidate()
        for _, window in ipairs(options.list()) do
            if slot_layout.eligible(window) and not closing[window.address]
                and window.workspace.addressable_name == options.parking then return window end
        end
    end

    function slots.place(window, request, keep_focus)
        if not slot_layout.eligible(window) or not request then return false end
        local state, index = request.state, request.index
        local source, source_index = locate(window)
        if request.other and source == state and source_index == state.focused then return false end
        local old = state.windows[index]
        if same(old, window) then return true end
        local original = hl.get_active_window()
        local retained_index = state.focused
        local source_visible = false
        if source then
            for _, monitor in ipairs(hl.get_monitors()) do
                if monitor.active_workspace and monitor.active_workspace.addressable_name == source.workspace then
                    source_visible = true
                end
            end
        end
        transaction(function()
            ratio_for(state)
            prepare(window)
            if old and alive(old, state) then
                swap(window, old)
                if source and source_visible then
                    source.windows[source_index] = old
                    source.revision = source.revision + 1
                else
                    options.move(old, options.parking)
                    if source then
                        source.windows[source_index] = nil
                        source.revision = source.revision + 1
                    end
                end
            else
                options.move(window, state.workspace)
                if source then
                    source.windows[source_index] = nil
                    source.revision = source.revision + 1
                end
            end
            state.windows[index] = window
            state.wanted = math.max(state.wanted, index)
            state.revision = state.revision + 1
            order(state)
            if source and source ~= state then order(source) end
            if keep_focus then
                focus(original)
            elseif request.other then
                focus(state.windows[retained_index] or window)
            else
                state.focused = index
                focus(window)
            end
            apply_ratio(state)
        end)
        return true
    end

    function slots.refill(preferred_state, preferred_index)
        if stopped or busy then return end
        transaction(function()
            local function fill(state, index)
                if state and not state.windows[index] then
                    local candidate = parking_candidate()
                    if candidate then slots.place(candidate, { state = state, index = index }, true) end
                end
            end
            if preferred_state and compositor.workspace_is_active(preferred_state.workspace) then
                fill(preferred_state, preferred_index)
            end
            for _, monitor in ipairs(hl.get_monitors()) do
                local workspace = monitor.active_workspace
                local state = workspace and states[workspace.addressable_name] and state_for(workspace)
                if state then
                    for index = 1, state.wanted do
                        fill(state, index)
                    end
                end
            end
        end)
    end

    function slots.schedule_refill()
        if stopped or busy or pending_refill then return end
        pending_refill = hl.timer(function()
            pending_refill = nil
            slots.refill()
        end, { timeout = 1, type = "oneshot" })
    end

    function slots.keep_only()
        local active = hl.get_active_window()
        local state = active and state_for(active.workspace)
        if not state or not slot_layout.eligible(active) then return end
        transaction(function()
            ratio_for(state)
            state.wanted, state.windows, state.focused = 1, { active }, 1
            state.revision = state.revision + 1
            for _, window in ipairs(members(active.workspace, active)) do options.move(window, options.parking) end
            prepare(active)
            focus(active)
            apply_ratio(state)
        end)
        slots.schedule_refill()
    end

    function slots.enable_two()
        local request = slots.capture()
        if not request then return end
        local state = request.state
        if state.wanted ~= 2 then
            state.wanted = 2
            state.revision = state.revision + 1
        end
        slots.refill(state, 3 - state.focused)
    end

    function slots.focus_next()
        local request = slots.capture()
        if not request then return end
        local state = request.state
        local target = state.windows[3 - state.focused]
        if target then state.focused = 3 - state.focused; focus(target) end
    end

    function slots.rotate()
        local request = slots.capture()
        if not request then return end
        local state = request.state
        local left, right = state.windows[1], state.windows[2]
        if not left or not right then return end
        transaction(function()
            swap(left, right)
            state.windows = { right, left }
            state.revision = state.revision + 1
            focus(state.windows[state.focused])
        end)
    end

    function slots.toggle_ratio()
        local request = slots.capture()
        if not request then return end
        local key, ratio = ratio_for(request.state)
        ratios[key] = ratio > 0.6 and 0.50 or 0.70
        apply_ratio(request.state)
    end

    function slots.opened(window, request)
        if not slot_layout.eligible(window) then return end
        local state = state_for(window.workspace, window)
        if not state then return end
        if request and request.state == state and request.revision ~= state.revision then
            options.move(window, options.parking)
            return
        end
        -- A remembered vacancy wins over replacement after Parking ran out.
        for index = 1, state.wanted do
            if not state.windows[index] then
                slots.place(window, { state = state, index = index }, true)
                return
            end
        end
        local target = request and request.state == state and request or { state = state, index = state.focused }
        slots.place(window, target, not compositor.workspace_is_active(state.workspace))
    end

    hl.on("window.close", function(window)
        if stopped or not window or not window.address then return end
        local state, index
        for _, candidate in pairs(states) do
            for slot = 1, 2 do
                if same(candidate.windows[slot], window) then state, index = candidate, slot end
            end
        end
        if not state then state, index = locate(window) end
        closing[window.address] = true
        if not state then
            closing[window.address] = nil
            return
        end
        local closed_address = window.address
        local was_focused = same(hl.get_active_window(), window)
        local close_epoch = focus_epoch
        state.windows[index] = nil
        state.revision = state.revision + 1
        hl.timer(function()
            if stopped then return end
            local active_before = hl.get_active_window()
            slots.refill(state, index)
            if was_focused and focus_epoch == close_epoch
                and compositor.workspace_is_active(state.workspace)
                and (hl.get_active_window() == active_before or same(hl.get_active_window(), active_before)) then
                focus(state.windows[index])
            end
            closing[closed_address] = nil
        end, { timeout = 1, type = "oneshot" })
    end)
    hl.on("window.active", function(window, reason)
        if stopped or busy or not window then return end
        if reason ~= 8192 and reason ~= 16384 and reason ~= 32768 then
            focus_epoch = focus_epoch + 1
        end
        local state, index = locate(window)
        if state then state.focused = index; apply_ratio(state) end
    end)
    hl.on("monitor.focused", function()
        if not stopped and not busy then focus_epoch = focus_epoch + 1 end
    end)
    hl.on("window.destroy", function(window)
        if window and window.address then closing[window.address] = nil end
    end)
    hl.on("workspace.active", function() slots.schedule_refill() end)
    hl.on("config.unload", function()
        stopped = true
        if not options.state_file then return end
        local file = io.open(options.state_file, "w")
        if not file then return end
        for key, state in pairs(states) do
            if not key:find("%c") then
                file:write(table.concat({ "slots", key, state.wanted, state.focused,
                    state.windows[1] and state.windows[1].address or "",
                    state.windows[2] and state.windows[2].address or "" }, "\t"), "\n")
            end
        end
        for key, ratio in pairs(ratios) do
            if not key:find("%c") then
                file:write(table.concat({ "ratio", key, tostring(ratio), "", "", "" }, "\t"), "\n")
            end
        end
        file:close()
    end)

    -- Capture before new window events; normalization is deferred until config loading ends.
    local excess = {}
    for _, workspace in ipairs(hl.get_workspaces()) do
        if managed(workspace) then
            local windows = members(workspace)
            if #windows > 0 then
                local state = state_for(workspace)
                for _, window in ipairs(windows) do
                    if not same(window, state.windows[1]) and not same(window, state.windows[2]) then
                        excess[#excess + 1] = window
                    end
                end
            end
        end
    end
    if #excess > 0 then
        hl.timer(function()
            if stopped then return end
            transaction(function()
                for _, window in ipairs(excess) do
                    if window.mapped then options.move(window, options.parking) end
                end
            end)
        end, { timeout = 1, type = "oneshot" })
    end

    return slots
end

return slot_layout
