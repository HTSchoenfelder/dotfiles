local config = require("config")
local midi = require("midi")
local windows = require("windows")

-- ==========================================
-- Globale Hotkeys
-- ==========================================

-- Rodecaster Mute Toggle
hs.hotkey.bind(config.hyper, "m", function()
    midi.toggleRodecasterMute()
end)

-- Window Manager Modal aktivieren (Hyper + .)
hs.hotkey.bind(config.hyper, ".", function()
    windows.enterMode()
end)


-- ==========================================
-- Window Manager Modal Hotkeys (Intern)
-- ==========================================
-- Wir binden die Tasten direkt an das exportierte Modal (windows.modal)

-- Fokus-Fenster verschieben
windows.modal:bind("", "h", function() windows.moveFocusedLeft() end)
windows.modal:bind("", "l", function() windows.moveFocusedRight() end)

-- Alle App-Fenster verschieben
windows.modal:bind({"shift"}, "h", function() windows.moveAppLeft() end)
windows.modal:bind({"shift"}, "l", function() windows.moveAppRight() end)

-- Alle Fenster aller Apps verschieben
windows.modal:bind({"shift"}, "h", function() windows.moveAllLeft() end)
windows.modal:bind({"shift"}, "l", function() windows.moveAllRight() end)

-- Fenster maximieren
windows.modal:bind("", "/", function() windows.maximizeFocused() end)
windows.modal:bind({"shift"}, "/", function() windows.maximizeAll() end)

-- Modal abbrechen (Escape)
windows.modal:bind("", "escape", function() windows.exitMode() end)