local process = require("lib.process")
local shortcut_catalog = require("lib.shortcut_catalog")

local function bind(key, command, description, repeating)
    hl.bind(key, function() process.spawn(command) end, {
        locked = true,
        repeating = repeating or false,
        description = description,
    })
    shortcut_catalog.add("Media", shortcut_catalog.format_key(key), description)
end

bind("XF86AudioRaiseVolume", { "wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+" }, "Raise volume", true)
bind("XF86AudioLowerVolume", { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-" }, "Lower volume", true)
bind("XF86AudioMute", { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle" }, "Toggle audio mute")
bind("XF86AudioMicMute", { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle" }, "Toggle microphone mute")
bind("XF86MonBrightnessUp", { "brightnessctl", "-e4", "-n2", "set", "5%+" }, "Raise brightness", true)
bind("XF86MonBrightnessDown", { "brightnessctl", "-e4", "-n2", "set", "5%-" }, "Lower brightness", true)

bind("XF86AudioNext", { "playerctl", "next" }, "Next track")
bind("XF86AudioPrev", { "playerctl", "previous" }, "Previous track")
bind("XF86AudioPlay", { "playerctl", "play-pause" }, "Play or pause")
bind("XF86AudioPause", { "playerctl", "play-pause" }, "Play or pause")
