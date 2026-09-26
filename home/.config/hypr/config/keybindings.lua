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
local compositor = require("lib.compositor")
local config_directory = assert(debug.getinfo(1, "S").source:match("^@(.*)/config/keybindings.lua$"))

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

shortcut_forwarding.bind(require("config.application_shortcuts"))

local function bind(key, action, description)
    return hl.bind(settings.modifier .. " + " .. key, action, { description = description })
end

local function add_to_stack()
    return hl.is_key_down(settings.stack_key:lower())
end

hl.layer_rule({ match = { namespace = "rofi" }, no_anim = true })
bind("R", function()
    windows.invalidate_pending_focus()
    picker.toggle_app_launcher()
end, "Toggle application launcher")
bind("W", hl.dsp.window.close(), "Close window")
bind("H", function() spaces.switch_between(workspaces.primary) end, "Switch between workspaces 1 and 2")
bind("M", hl.dsp.layout("cyclenext"), "Focus next window")
bind("N", window_navigation.rotate_positions, "Rotate window positions")

bind(settings.stack_key, picker.add_to_stack, "Add selection to stack")
bind(settings.instance_key, hl.dsp.no_op(), "Select application instance")
local spotify
for _, application in ipairs(settings.applications) do
    if application.class == "spotify" then spotify = application end
    bind(application.key, function()
        windows.activate(application, add_to_stack(), hl.is_key_down(settings.instance_key:lower()))
    end, "Navigate to " .. application.name)
end
assert(spotify, "Spotify must be configured as a navigation application")

bind("P", function() windows.activate(nil, add_to_stack(), true) end, "Select window by last focus")
picker.bind_cycle("comma", function(direction)
    windows.cycle(direction, "comma", add_to_stack())
end, "Cycle windows by last focus")
picker.bind_cycle("G", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    spaces.cycle(direction, "G")
end, "Cycle workspaces by last focus")
picker.bind_cycle("Y", function(direction)
    if picker.is_open() then return end
    windows.invalidate_pending_focus()
    local stack = add_to_stack()
    media_controls.cycle(picker, {
        key = "Y", direction = direction, player = "spotify",
        open_spotify = function() windows.activate(spotify, stack, false) end,
    })
end, "Cycle player actions")

bind("period", function()
    windows.invalidate_pending_focus()
    picker.cancel()
    compositor.dispatch(hl.dsp.submap("actions"))
end, "Enter action mode")

hl.define_submap("actions", function()
    local function run_action(action)
        return function()
            -- Release the submap before a launcher or capture tool takes focus.
            compositor.dispatch(hl.dsp.submap("reset"))
            action()
        end
    end
    hl.bind("Q", run_action(screenshots.capture_region), { ignore_mods = true, description = "Capture region" })
    hl.bind("W", run_action(screenshots.capture_active_output), { ignore_mods = true, description = "Capture active screen" })
    hl.bind("E", run_action(function()
        text_launcher.open(picker, config_directory .. "/launcher-data/emoji.txt", text_launcher.emoji)
    end), { ignore_mods = true, description = "Insert emoji" })
    hl.bind("R", run_action(function()
        command_launcher.open(picker, config_directory .. "/launcher-data/execute.txt")
    end), { ignore_mods = true, description = "Run configured command" })
    hl.bind("T", run_action(function()
        text_launcher.open(picker, config_directory .. "/launcher-data/snippets.txt", text_launcher.snippet)
    end), { ignore_mods = true, description = "Insert snippet" })
    hl.bind("Escape", hl.dsp.submap("reset"), { ignore_mods = true, description = "Cancel action mode" })
    hl.bind("catchall", hl.dsp.submap("reset"), { ignore_mods = true })
end)
