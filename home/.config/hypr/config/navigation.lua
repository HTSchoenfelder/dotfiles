-- Load the literal filename: require() would turn its dots into directories.
local config_dir = assert(debug.getinfo(1, "S").source:match("^@(.*/)"))
local navigation = dofile(config_dir .. "navigation.helper.lua")

local workspace_cycle = { 1, 2 }
local parking_workspace = 10 -- Parking is shown as an icon in the workspace bar.

hl.config({
    general = { layout = "master" },
    master = {
        orientation = "left",
        mfact = 0.70,
        new_status = "slave",
    },
    -- Moving a selected window should not merge it into an existing tab group.
    group = { group_on_movetoworkspace = false },
})

hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.workspace_rule({
    workspace = "1",
    layout = "master",
    default_name = "",
})
hl.workspace_rule({
    workspace = "2",
    default_name = "󰍹",
})
hl.workspace_rule({
    workspace = tostring(parking_workspace),
    default_name = "󰮍",
})

navigation.setup({
    mod = mainMod,
    side_key = "f",
    picker_key = "a",
    all_windows_key = "P",
    cycle_key = "comma",
    cycle_reverse_mod = "SHIFT",
    cycle_cancel_key = "Escape",
    cycle_rows = 7,
    parking_workspace = parking_workspace,
    launch_timeout_ms = 15000,
    apps = {
        {
            name = "Kitty / Zellij",
            key = "J",
            command = "env START_ZELLIJ=1 kitty",
            matches = navigation.by_class("kitty"),
        },
        {
            name = "VS Code",
            key = "K",
            command = "code",
            matches = navigation.by_class("code"),
        },
        {
            name = "Chrome",
            key = "L",
            command = "google-chrome-stable",
            matches = navigation.by_class("google-chrome"),
        },
        {
            name = "Obsidian",
            key = "semicolon",
            command = "obsidian",
            matches = navigation.by_class("obsidian"),
        },
        {
            name = "KeePassXC",
            key = "O",
            command = "keepassxc",
            matches = navigation.by_class("org.keepassxc.KeePassXC"),
        },
        {
            name = "Spotify",
            key = "U",
            command = "spotify",
            matches = navigation.by_class("spotify"),
        },
    },
})

hl.bind(mainMod .. " + H", function()
    navigation.cycle_workspaces(workspace_cycle)
end, { description = "Switch between workspaces 1 and 2" })
hl.bind(mainMod .. " + M", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + N", navigation.rotate_windows)
