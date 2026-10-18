local settings = require("config.navigation")
local workspaces = require("config.workspaces")
local rofi_picker = require("lib.rofi_picker")
local window_navigation = require("lib.window_navigation")
local workspace_navigation = require("lib.workspace_navigation")
local media_controls = require("lib.media_controls")
local text_launcher = require("lib.text_launcher")
local command_launcher = require("lib.command_launcher")
local process = require("lib.process")
local shortcut_forwarding = require("lib.shortcut_forwarding")
local screenshots = require("lib.screenshots")
local dot_mode = require("lib.dot_mode")
local monitor_configuration = require("lib.monitor_configuration")
local project_overlays = require("lib.project_overlays")
local workspace_reset = require("lib.workspace_reset")
local shortcut_catalog = require("lib.shortcut_catalog")
local config_directory = assert(debug.getinfo(1, "S").source:match("^@(.*)/config/keybindings.lua$"))

shortcut_catalog.reset()

local picker = rofi_picker.new({
    modifier = settings.modifier,
    rows = settings.cycle_rows,
    provider = config_directory .. "/lib/rofi_mode.lua",
})
local windows = window_navigation.new({
    parking_workspace = workspaces.parking,
    launch_timeout_ms = settings.launch_timeout_ms,
    state_file = settings.slot_state_file,
}, picker)
local spaces = workspace_navigation.new(picker)
local overlays = project_overlays.new(require("config.project_overlays"))

shortcut_forwarding.bind(require("config.application_shortcuts"), shortcut_catalog)

local function bind(key, action, description, section)
    shortcut_catalog.add(section or "Navigation", shortcut_catalog.main(key), description, function()
        if type(action) == "function" then action() else hl.dispatch(action) end
    end)
    return hl.bind(settings.modifier .. " + " .. key, action, { description = description })
end

hl.layer_rule({ match = { namespace = "rofi" }, no_anim = true })
bind("R", function()
    windows.invalidate_pending_focus()
    picker.toggle_app_launcher()
end, "Toggle application launcher", "Launchers")
bind("W", hl.dsp.window.close(), "Close window", "Windows")
bind("H", windows.focus_other_monitor, "Focus other display", "Navigation")
bind("slash", windows.keep_focused_only, "Keep focused slot only", "Windows")
bind("SHIFT + slash", windows.enable_two_slots, "Use two slots on focused display", "Windows")
bind("M", windows.focus_next_slot, "Focus other slot", "Navigation")
bind("N", windows.rotate_positions, "Swap slot contents and retain focused side", "Windows")

hl.bind(settings.modifier .. " + " .. settings.other_slot_key, hl.dsp.no_op(),
    { description = "Target other slot" })
hl.bind(settings.modifier .. " + " .. settings.filter_key, hl.dsp.no_op(),
    { description = "Filter application instances" })
local terminal
local applications_by_id = {}
for _, application in ipairs(settings.applications) do
    assert(application.id and not applications_by_id[application.id], "Application IDs must be unique")
    applications_by_id[application.id] = application
end
local function focused_application()
    local active = hl.get_active_window()
    if not active then return end
    for _, application in ipairs(settings.applications) do
        if active.class:lower() == application.class:lower() then return application end
    end
    return { class = active.class }
end

local function selection_target()
    return hl.is_key_down(settings.other_slot_key:lower()) and "other" or "focused"
end

for _, application in ipairs(settings.applications) do
    if application.class == "kitty" then terminal = application end
    if application.key then
        bind(application.key, function()
            windows.activate(application, { target = selection_target() },
                hl.is_key_down(settings.filter_key:lower()))
        end, "Fill focused slot with " .. application.name, "Applications")
        shortcut_catalog.add("Applications", shortcut_catalog.main("F + " .. application.key),
            "Select " .. application.name .. " instance", function()
                windows.activate(application, {}, true)
            end)
        shortcut_catalog.add("Applications", shortcut_catalog.main("S + " .. application.key),
            "Fill other slot with " .. application.name, function()
                windows.activate(application, { target = "other" }, false)
            end)
        shortcut_catalog.add("Applications", shortcut_catalog.main("F + S + " .. application.key),
            "Select " .. application.name .. " instance for other slot", function()
                windows.activate(application, { target = "other" }, true)
            end)
    end
end
assert(terminal, "Kitty must be configured as a navigation application")

local function cycle_application_group(group, direction, filtered, target)
    if picker.is_open() then return end
    local items = {}
    for _, id in ipairs(group.applications) do
        local application = assert(applications_by_id[id], "Unknown grouped application: " .. id)
        items[#items + 1] = { label = application.name, application = application }
    end
    picker.open(items, {
        cycle_key = group.key,
        initial_index = direction > 0 and 1 or #items,
        on_select = function(item)
            windows.activate(item.application, { target = target }, filtered)
        end,
    })
end

for _, group in ipairs(settings.application_groups) do
    local current_group = group
    picker.bind_cycle(current_group.key, function(direction)
        cycle_application_group(current_group, direction,
            hl.is_key_down(settings.filter_key:lower()), selection_target())
    end, "Cycle " .. current_group.name .. " applications")
    for _, combination in ipairs({
        { key = current_group.key, direction = 1, filtered = false, target = "focused", suffix = "" },
        { key = "SHIFT + " .. current_group.key, direction = -1, filtered = false, target = "focused", suffix = " backwards" },
        { key = "F + " .. current_group.key, direction = 1, filtered = true, target = "focused", suffix = " with instance selection" },
        { key = "F + SHIFT + " .. current_group.key, direction = -1, filtered = true, target = "focused", suffix = " backwards with instance selection" },
        { key = "S + " .. current_group.key, direction = 1, filtered = false, target = "other", suffix = " for other slot" },
        { key = "S + SHIFT + " .. current_group.key, direction = -1, filtered = false, target = "other", suffix = " backwards for other slot" },
        { key = "F + S + " .. current_group.key, direction = 1, filtered = true, target = "other", suffix = " with instance selection for other slot" },
        { key = "F + S + SHIFT + " .. current_group.key, direction = -1, filtered = true, target = "other", suffix = " backwards with instance selection for other slot" },
    }) do
        local current = combination
        shortcut_catalog.add("Applications", shortcut_catalog.main(combination.key),
            "Cycle " .. current_group.name .. " applications" .. combination.suffix, function()
                cycle_application_group(current_group, current.direction, current.filtered, current.target)
            end)
    end
end
local reset_workspaces = workspace_reset.new({
    workspaces = workspaces,
    activate_terminal = function() windows.activate(terminal, { replace_layout = true }, false) end,
})
monitor_configuration.set_workspace_reconciler(reset_workspaces.restore_roles)

local function open_commands()
    command_launcher.open(picker, config_directory .. "/launcher-data/execute.txt", {
        ["reset-workspaces"] = reset_workspaces.run,
    })
end

bind("SHIFT + P", function() shortcut_catalog.open(picker) end,
    "Show shortcut catalog", "Launchers")
bind("SHIFT + R", open_commands, "Run configured command", "Launchers")
local config_home = os.getenv("XDG_CONFIG_HOME")
    or (os.getenv("HOME") and os.getenv("HOME") .. "/.config")
if config_home then
    bind("V", hl.dsp.exec_cmd(process.command({
        "lua",
        config_directory .. "/lib/clipboard_history_picker.lua",
        config_home .. "/clipse/clipboard_history.json",
    })), "Paste from clipboard history", "Launchers")
end
local function select_windows(filtered, target)
    local application = filtered and focused_application() or nil
    if filtered and not application then return end
    windows.activate(application, { target = target }, true)
end
bind("P", function()
    select_windows(
        hl.is_key_down(settings.filter_key:lower()), selection_target()
    )
end, "Select window for focused slot", "Windows")
shortcut_catalog.add("Windows", shortcut_catalog.main("F + P"), "Select focused application window",
    function() select_windows(true, "focused") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("S + P"), "Select window for other slot",
    function() select_windows(false, "other") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("F + S + P"),
    "Select focused application window for other slot", function() select_windows(true, "other") end)
local function cycle_windows(direction, filtered, target)
    local application = filtered and focused_application() or nil
    if filtered and not application then return end
    windows.cycle(direction, "comma", { target = target }, application)
end
picker.bind_cycle("comma", function(direction)
    cycle_windows(
        direction,
        hl.is_key_down(settings.filter_key:lower()), selection_target()
    )
end, "Cycle windows by last focus")
shortcut_catalog.add("Windows", shortcut_catalog.main("comma"), "Choose focused slot content by last focus",
    function() cycle_windows(1, false, "focused") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("SHIFT + comma"), "Cycle windows backwards",
    function() cycle_windows(-1, false, "focused") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("F + comma"), "Cycle application windows",
    function() cycle_windows(1, true, "focused") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("F + SHIFT + comma"),
    "Cycle application windows backwards", function() cycle_windows(-1, true, "focused") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("S + comma"),
    "Choose other slot content by last focus", function() cycle_windows(1, false, "other") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("S + SHIFT + comma"),
    "Cycle other slot windows backwards", function() cycle_windows(-1, false, "other") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("F + S + comma"),
    "Cycle application windows for other slot", function() cycle_windows(1, true, "other") end)
shortcut_catalog.add("Windows", shortcut_catalog.main("F + S + SHIFT + comma"),
    "Cycle application windows backwards for other slot", function() cycle_windows(-1, true, "other") end)
picker.bind_cycle("B", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    spaces.cycle(direction, "B")
end, "Cycle workspaces by last focus")
shortcut_catalog.add("Navigation", shortcut_catalog.main("B"), "Cycle workspaces by last focus",
    function() spaces.cycle(1, "B") end)
shortcut_catalog.add("Navigation", shortcut_catalog.main("SHIFT + B"), "Cycle workspaces backwards",
    function() spaces.cycle(-1, "B") end)
picker.bind_cycle("Y", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    local target = selection_target()
    local filtered = hl.is_key_down(settings.filter_key:lower())
    media_controls.cycle(picker, { key = "Y", direction = direction, player = "spotify",
        open = function() windows.activate(applications_by_id.spotify, { target = target }, filtered) end })
end, "Cycle Spotify and player actions")
shortcut_catalog.add("Media", shortcut_catalog.main("Y"), "Cycle Spotify and player actions", function()
    media_controls.cycle(picker, { key = "Y", direction = 1, player = "spotify",
        open = function() windows.activate(applications_by_id.spotify, { target = "focused" }, false) end })
end)
shortcut_catalog.add("Media", shortcut_catalog.main("SHIFT + Y"), "Cycle Spotify and player actions backwards", function()
    media_controls.cycle(picker, { key = "Y", direction = -1, player = "spotify",
        open = function() windows.activate(applications_by_id.spotify, { target = "focused" }, false) end })
end)

dot_mode.bind({
    modifier = settings.modifier,
    catalog = shortcut_catalog,
    before_enter = function()
        windows.invalidate_pending_focus()
        picker.cancel()
    end,
    actions = {
        { key = "slash", description = "Toggle display split between 70:30 and 50:50", run = windows.toggle_ratio },
        { key = "Q", description = "Capture region", run = screenshots.capture_region },
        { key = "A", description = "Capture active window", run = screenshots.capture_active_window },
        { key = "Z", description = "Capture active screen", run = screenshots.capture_active_output },
        { key = "B", description = "Toggle display", run = function()
            monitor_configuration.open(picker)
        end },
        { key = "V", description = "Toggle project Neovim", run = function()
            overlays.toggle("editor")
        end },
        { key = "G", description = "Toggle project Lazygit", run = function()
            overlays.toggle("git")
        end },
        { key = "J", description = "Toggle project terminal", run = function()
            overlays.toggle("terminal")
        end },
        { key = "W", description = "Hide all project overlays", run = overlays.hide_all },
        { key = "E", description = "Insert emoji", run = function()
            text_launcher.open(picker, config_directory .. "/launcher-data/emoji.txt", text_launcher.emoji)
        end },
        { key = "T", description = "Insert snippet", run = function()
            text_launcher.open(picker, config_directory .. "/launcher-data/snippets.txt", text_launcher.snippet)
        end },
    },
})
