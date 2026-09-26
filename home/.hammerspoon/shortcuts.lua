local config = require("config")
local midi = require("midi")
local catalog = require("shortcut_catalog")
local windows = require("windows")

-- Keep the keyboard MIDI toggle available without occupying window focus navigation.
hs.hotkey.bind({"alt", "ctrl", "cmd", "shift"}, "m", function()
    midi.toggleRodecasterMute()
end)
catalog.add("Media", "MainMod + Shift + M", "Toggle RØDECaster mute")

-- Open the existing window action mode.
hs.hotkey.bind(config.hyper, ".", function()
    windows.enterMode()
end)
catalog.add("Dot mode", "MainMod + .", "Enter window action mode")


-- Move the focused window between displays.
windows.modal:bind("", "h", function() windows.moveFocusedLeft() end)
windows.modal:bind("", "l", function() windows.moveFocusedRight() end)
catalog.add("Dot mode", "MainMod + . → H", "Move focused window left")
catalog.add("Dot mode", "MainMod + . → L", "Move focused window right")

-- Move every visible window between displays.
windows.modal:bind({"shift"}, "h", function() windows.moveAllLeft() end)
windows.modal:bind({"shift"}, "l", function() windows.moveAllRight() end)
catalog.add("Dot mode", "MainMod + . → Shift + H", "Move visible windows left")
catalog.add("Dot mode", "MainMod + . → Shift + L", "Move visible windows right")

-- Maximize one or all windows.
windows.modal:bind("", "/", function() windows.maximizeFocused() end)
windows.modal:bind({"shift"}, "/", function() windows.maximizeAll() end)
catalog.add("Dot mode", "MainMod + . → /", "Maximize focused window")
catalog.add("Dot mode", "MainMod + . → Shift + /", "Maximize all windows")

windows.modal:bind("", "escape", function() windows.exitMode() end)
catalog.add("Dot mode", "MainMod + . → Escape", "Leave window action mode")
