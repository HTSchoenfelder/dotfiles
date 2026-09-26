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
}, picker)
local spaces = workspace_navigation.new(picker)
local overlays = project_overlays.new(require("config.project_overlays"))

shortcut_forwarding.bind(require("config.application_shortcuts"), shortcut_catalog)

local function bind(key, action, description, section)
    shortcut_catalog.add(section or "Navigation", shortcut_catalog.main(key), description)
    return hl.bind(settings.modifier .. " + " .. key, action, { description = description })
end

local function add_to_stack()
    return hl.is_key_down(settings.stack_key:lower())
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
bind("H", function() spaces.switch_between(workspaces.primary) end, "Switch between workspaces 1 and 2", "Navigation")
bind("M", hl.dsp.layout("cyclenext"), "Focus next window", "Navigation")
bind("N", window_navigation.rotate_positions, "Rotate window positions", "Windows")

bind(settings.stack_key, picker.add_to_stack, "Add selection to stack", "Applications")
bind(settings.instance_key, hl.dsp.no_op(), "Select application instance", "Applications")
local spotify, terminal
local function focused_application()
    local active = hl.get_active_window()
    if not active then return end
    for _, application in ipairs(settings.applications) do
        if active.class:lower() == application.class:lower() then return application end
    end
    return { class = active.class }
end

for _, application in ipairs(settings.applications) do
    if application.class == "spotify" then spotify = application end
    if application.class == "kitty" then terminal = application end
    bind(application.key, function()
        windows.activate(application, add_to_stack(), hl.is_key_down(settings.instance_key:lower()))
    end, "Navigate to " .. application.name, "Applications")
end
assert(spotify, "Spotify must be configured as a navigation application")
assert(terminal, "Kitty must be configured as a navigation application")
local reset_workspaces = workspace_reset.new({
    workspaces = workspaces,
    activate_terminal = function() windows.activate(terminal, false, false) end,
})

bind("P", function() windows.activate(nil, add_to_stack(), true) end, "Select window by last focus", "Windows")
picker.bind_cycle("comma", function(direction)
    local application = hl.is_key_down(settings.instance_key:lower()) and focused_application() or nil
    windows.cycle(direction, "comma", add_to_stack(), application)
end, "Cycle windows by last focus")
shortcut_catalog.add("Windows", shortcut_catalog.main("comma"), "Cycle windows by last focus")
shortcut_catalog.add("Windows", shortcut_catalog.main("SHIFT + comma"), "Cycle windows backwards")
shortcut_catalog.add("Windows", shortcut_catalog.main("A + comma"), "Cycle application windows")
picker.bind_cycle("G", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    spaces.cycle(direction, "G")
end, "Cycle workspaces by last focus")
shortcut_catalog.add("Navigation", shortcut_catalog.main("G"), "Cycle workspaces by last focus")
shortcut_catalog.add("Navigation", shortcut_catalog.main("SHIFT + G"), "Cycle workspaces backwards")
picker.bind_cycle("Y", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    local stack = add_to_stack()
    media_controls.cycle(picker, {
        key = "Y", direction = direction, player = "spotify",
        open_spotify = function() windows.activate(spotify, stack, false) end,
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
