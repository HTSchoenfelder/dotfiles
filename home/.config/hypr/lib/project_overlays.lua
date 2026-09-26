local compositor = require("lib.compositor")
local process = require("lib.process")
local project_overlays = {}
local prefix = "project-overlay-"

function project_overlays.is_overlay(window)
    return window and window.class:sub(1, #prefix) == prefix
end

function project_overlays.project(window)
    if not window then return end
    if project_overlays.is_overlay(window) then
        local encoded = window.class:match("^project%-overlay%-%a+%-(%x+)$")
        if encoded and #encoded % 2 == 0 then
            return (encoded:gsub("..", function(byte) return string.char(tonumber(byte, 16)) end))
        end
    elseif window.class:lower() == "code" then
        local path = window.title:match("^(.-)%s+|%s+Code$")
        if path then
            path = path:gsub("^~", function() return assert(os.getenv("HOME")) end)
            if path:sub(1, 1) == "/" and not path:find("[%z\r\n]") then return path end
        end
    end
end

local function window_class(tool, project)
    return prefix .. tool .. "-" .. project:gsub(".", function(byte) return string.format("%02x", byte:byte()) end)
end

function project_overlays.new(settings)
    local overlays = {}
    local pending = {}
    local latest_request
    local finish_timer

    local function find(class)
        for _, window in ipairs(hl.get_windows({ mapped = true })) do
            if window.class == class then return window end
        end
    end

    local function hide(window)
        if window.workspace and window.workspace.addressable_name ~= settings.workspace then
            compositor.dispatch(hl.dsp.window.move({ window = window, workspace = settings.workspace, follow = false }))
        end
    end

    local function hide_visible(except)
        for _, window in ipairs(hl.get_windows({ mapped = true })) do
            if project_overlays.is_overlay(window) and (not except or window.address ~= except.address) then hide(window) end
        end
    end

    local function request_is_current(window, request)
        return request == latest_request
            and window.mapped ~= false
            and compositor.workspace_is_active(request.workspace)
    end

    local function schedule(callback)
        hl.timer(callback, { timeout = settings.settle_delay_ms, type = "oneshot" })
    end

    local function fail_show(window, request)
        if request ~= latest_request then return end
        latest_request = nil
        hide(window)
        compositor.notify("Project overlay could not become floating.")
    end

    local prepare
    local function place(window, request, attempt)
        if not request_is_current(window, request) then return end
        if not window.workspace or window.workspace.addressable_name ~= request.workspace or not window.floating then
            prepare(window, request, attempt + 1)
            return
        end
        local workspace = hl.get_workspace(request.workspace)
        local monitor = workspace and workspace.monitor or window.monitor
        if monitor then
            compositor.dispatch(hl.dsp.window.resize({
                window = window,
                x = math.floor(monitor.width * 0.95),
                y = math.floor(monitor.height * 0.90),
            }))
        end
        schedule(function()
            if not request_is_current(window, request) then return end
            if not window.floating then
                prepare(window, request, attempt + 1)
                return
            end
            if monitor then
                local result = hl.dispatch(hl.dsp.window.center({ window = window }))
                if not result.ok and result.error == "No floating window found" then
                    prepare(window, request, attempt + 1)
                    return
                end
                assert(result.ok, result.error or "Hyprland action failed")
            end
            compositor.dispatch(hl.dsp.focus({ window = window }))
            compositor.dispatch(hl.dsp.window.deny_from_group({ action = "set" }))
        end)
    end

    prepare = function(window, request, attempt)
        if not request_is_current(window, request) then return end
        if attempt > settings.settle_attempts then
            fail_show(window, request)
            return
        end
        if not window.workspace or window.workspace.addressable_name ~= request.workspace then
            schedule(function() prepare(window, request, attempt + 1) end)
            return
        end
        if not window.floating then
            compositor.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
        end
        schedule(function() place(window, request, attempt) end)
    end

    local function show(window, request)
        hide_visible(window)
        if not window.workspace or window.workspace.addressable_name ~= request.workspace then
            compositor.dispatch(hl.dsp.window.move({ window = window, workspace = request.workspace, follow = false }))
        end
        schedule(function() prepare(window, request, 1) end)
    end

    local function finish_launches()
        for class, request in pairs(pending) do
            local window = find(class)
            if window then
                pending[class] = nil
                if request == latest_request and compositor.workspace_is_active(request.workspace) then
                    show(window, request)
                else
                    hide(window)
                end
            end
        end
    end

    local function schedule_launch_completion()
        if not next(pending) or finish_timer then return end
        finish_timer = hl.timer(function()
            finish_timer = nil
            finish_launches()
        end, { timeout = 50, type = "oneshot" })
    end
    for _, event in ipairs({ "window.open", "window.class" }) do
        hl.on(event, schedule_launch_completion)
    end
    for _, event in ipairs({ "workspace.active", "monitor.focused" }) do
        hl.on(event, function()
            latest_request = nil
            hide_visible()
        end)
    end
    hl.on("config.unload", function() latest_request = nil end)

    function overlays.toggle(tool)
        local origin = hl.get_active_window()
        local project = project_overlays.project(origin)
        local workspace = compositor.active_workspace()
        if not project or not workspace or workspace.special then
            compositor.notify("Focus a project in VS Code or an existing project overlay.")
            return
        end
        local directory = io.open(project .. "/.", "r")
        if not directory then
            compositor.notify("Project directory is unavailable: " .. project)
            return
        end
        directory:close()
        local definition = assert(settings.tools[tool], "Unknown project overlay")
        local class = window_class(tool, project)
        local window = find(class)
        if window and window.workspace.addressable_name == workspace.addressable_name then
            latest_request = nil
            hide(window)
            return
        end
        local request = { workspace = workspace.addressable_name }
        latest_request = request
        if window then show(window, request); return end
        if pending[class] then
            -- Repeated requests reuse the single in-flight launch.
            pending[class] = request
            return
        end
        pending[class] = request
        hide_visible()
        local arguments = { "env", "START_ZELLIJ=0", "kitty", "--class", class,
            "--title", project .. " | " .. definition.title, "--working-directory", project }
        for _, argument in ipairs(definition.command) do arguments[#arguments + 1] = argument end
        process.spawn(arguments, { workspace = request.workspace .. " silent", no_initial_focus = true })
        hl.timer(function()
            if pending[class] then
                pending[class] = nil
                compositor.notify("Project overlay did not open: " .. definition.title)
            end
        end, { timeout = settings.launch_timeout_ms, type = "oneshot" })
    end

    return overlays
end

return project_overlays
