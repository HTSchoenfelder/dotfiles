local settings = require("config.navigation")
local workspaces = require("config.workspaces")
local rofi_picker = require("lib.rofi_picker")
local window_navigation = require("lib.window_navigation")
local workspace_navigation = require("lib.workspace_navigation")
local media_controls = require("lib.media_controls")
local text_launcher = require("lib.text_launcher")
local command_launcher = require("lib.command_launcher")
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
    shortcut_catalog.add(section or "Navigation", shortcut_catalog.main(key), description)
    return hl.bind(settings.modifier .. " + " .. key, action, { description = description })
end

hl.layer_rule({ match = { namespace = "rofi" }, no_anim = true })
bind("R", function()
    windows.invalidate_pending_focus()
    picker.toggle_app_launcher()
end, "Toggle application launcher", "Launchers")
bind("SHIFT + R", function()
    shortcut_catalog.open(picker)
end, "Show shortcut catalog", "Launchers")
bind("W", hl.dsp.window.close(), "Close window", "Windows")
bind("H", windows.focus_other_monitor, "Focus other display", "Navigation")
bind("slash", windows.keep_focused_only, "Keep focused slot only", "Windows")
bind("SHIFT + slash", windows.enable_two_slots, "Use two slots on focused display", "Windows")
bind("M", windows.focus_next_slot, "Focus other slot", "Navigation")
bind("N", windows.rotate_positions, "Swap slot contents and retain focused side", "Windows")

bind(settings.instance_key, hl.dsp.no_op(), "Select application instance", "Applications")
shortcut_catalog.add("Applications", shortcut_catalog.main("F + App"), "Select application instance")
shortcut_catalog.add("Applications", shortcut_catalog.main("SHIFT + App"), "Fill other slot with application")
local terminal
local function focused_application()
    local active = hl.get_active_window()
    if not active then return end
    for _, application in ipairs(settings.applications) do
        if active.class:lower() == application.class:lower() then return application end
    end
    return { class = active.class }
end

for _, application in ipairs(settings.applications) do
    if application.class == "kitty" then terminal = application end
    bind(application.key, function()
        windows.activate(application, {}, hl.is_key_down(settings.instance_key:lower()))
    end, "Fill focused slot with " .. application.name, "Applications")
    hl.bind(settings.modifier .. " + SHIFT + " .. application.key, function()
        windows.activate(application, { other_slot = true }, hl.is_key_down(settings.instance_key:lower()))
    end, { description = "Fill other slot with " .. application.name })
end
assert(terminal, "Kitty must be configured as a navigation application")
local reset_workspaces = workspace_reset.new({
    workspaces = workspaces,
    activate_terminal = function() windows.activate(terminal, { replace_layout = true }, false) end,
})

bind("P", function() windows.activate(nil, {}, true) end, "Select window for focused slot", "Windows")
hl.bind(settings.modifier .. " + SHIFT + P", function()
    windows.activate(nil, { other_slot = true }, true)
end, { description = "Select window for other slot" })
picker.bind_cycle("comma", function(direction)
    local application = hl.is_key_down(settings.instance_key:lower()) and focused_application() or nil
    windows.cycle(direction, "comma", {}, application)
end, "Cycle windows by last focus")
shortcut_catalog.add("Windows", shortcut_catalog.main("comma"), "Choose focused slot content by last focus")
shortcut_catalog.add("Windows", shortcut_catalog.main("SHIFT + comma"), "Cycle windows backwards")
shortcut_catalog.add("Windows", shortcut_catalog.main("F + comma"), "Cycle application windows")
shortcut_catalog.add("Windows", shortcut_catalog.main("SHIFT + P"), "Select window for other slot")
picker.bind_cycle("B", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    spaces.cycle(direction, "B")
end, "Cycle workspaces by last focus")
shortcut_catalog.add("Navigation", shortcut_catalog.main("B"), "Cycle workspaces by last focus")
shortcut_catalog.add("Navigation", shortcut_catalog.main("SHIFT + B"), "Cycle workspaces backwards")
picker.bind_cycle("Y", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    media_controls.cycle(picker, {
        key = "Y", direction = direction, player = "spotify",
    })
end, "Cycle player actions")
shortcut_catalog.add("Media", shortcut_catalog.main("Y"), "Cycle player actions")
shortcut_catalog.add("Media", shortcut_catalog.main("SHIFT + Y"), "Cycle player actions backwards")

dot_mode.bind({
    modifier = settings.modifier,
    catalog = shortcut_catalog,
    before_enter = function()
        windows.invalidate_pending_focus()
        picker.cancel()
    end,
    actions = {
        { key = "M", description = "Toggle display split between 70:30 and 50:50", run = windows.toggle_ratio },
        { key = "Q", description = "Capture region", run = screenshots.capture_region },
        { key = "A", description = "Capture active window", run = screenshots.capture_active_window },
        { key = "Z", description = "Capture active screen", run = screenshots.capture_active_output },
        { key = "B", description = "Toggle display", run = function()
            monitor_configuration.open(picker)
        end },
        { key = "G", description = "Toggle project editor", run = function()
            overlays.toggle("editor")
        end },
        { key = "SHIFT + G", description = "Toggle project Git client", run = function()
            overlays.toggle("git")
        end },
        { key = "J", description = "Toggle project terminal", run = function()
            overlays.toggle("terminal")
        end },
        { key = "E", description = "Insert emoji", run = function()
            text_launcher.open(picker, config_directory .. "/launcher-data/emoji.txt", text_launcher.emoji)
        end },
        { key = "R", description = "Run configured command", run = function()
            command_launcher.open(picker, config_directory .. "/launcher-data/execute.txt", {
                ["reset-workspaces"] = reset_workspaces.run,
            })
        end },
        { key = "T", description = "Insert snippet", run = function()
            text_launcher.open(picker, config_directory .. "/launcher-data/snippets.txt", text_launcher.snippet)
        end },
    },
})
