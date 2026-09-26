local config = require("config")
local midi = require("midi")
local windows = require("windows")

-- Keep the keyboard MIDI toggle available without occupying window focus navigation.
hs.hotkey.bind({"alt", "ctrl", "cmd", "shift"}, "m", function()
    midi.toggleRodecasterMute()
end)

-- Open the existing window action mode.
hs.hotkey.bind(config.hyper, ".", function()
    windows.enterMode()
end)


-- Move the focused window between displays.
windows.modal:bind("", "h", function() windows.moveFocusedLeft() end)
windows.modal:bind("", "l", function() windows.moveFocusedRight() end)

-- Move every visible window between displays.
windows.modal:bind({"shift"}, "h", function() windows.moveAllLeft() end)
windows.modal:bind({"shift"}, "l", function() windows.moveAllRight() end)

-- Maximize one or all windows.
windows.modal:bind("", "/", function() windows.maximizeFocused() end)
windows.modal:bind({"shift"}, "/", function() windows.maximizeAll() end)

windows.modal:bind("", "escape", function() windows.exitMode() end)
