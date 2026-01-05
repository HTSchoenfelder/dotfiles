local M = {}

local terminalApps = {
    ["net.kovidgoyal.kitty"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true
}

-- Standard Ctrl -> Cmd Map
local ctrlToCmdMap = {
    [0]  = "a", [8]  = "c", [9]  = "v", [7]  = "x", 
    [3]  = "f", [6]  = "z", [1]  = "s", [17] = "t",
    [45] = "n", [13] = "w", [35] = "p", [16] = "y"
}

-- Navigation Map
local ctrlToOptionMap = {
    [123] = "left", [124] = "right", [51] = "delete", [117] = "forwarddelete"
}

M.start = function()
    M.tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        local app = hs.application.frontmostApplication()
        if not app then return false end
        local bundleID = app:bundleID()
        local isTerm = terminalApps[bundleID]
        local isChrome = (bundleID == "com.google.Chrome")

        -- 1. TERMINAL PRIORITÄT (Pass-through für SIGINT)
        if isTerm then
            if flags.ctrl and flags.shift and not (flags.cmd or flags.alt) then
                if keyCode == 8 then hs.eventtap.keyStroke({"cmd"}, "c", 0); return true end
                if keyCode == 9 then hs.eventtap.keyStroke({"cmd"}, "v", 0); return true end
                if keyCode == 6 then hs.eventtap.keyStroke({"cmd", "shift"}, "z", 0); return true end
            end
            return false -- In Kitty/Terminals machen wir sonst NICHTS
        end

        -- 2. CHROME SPEZIAL LOGIK (Physisch Ctrl + J/K/P)
        if isChrome and flags.ctrl and not (flags.cmd or flags.alt) then
            if keyCode == 40 then -- Taste 'k' -> Next Tab
                hs.eventtap.keyStroke({"ctrl"}, "tab", 0)
                return true
            elseif keyCode == 38 then -- Taste 'j' -> Prev Tab
                hs.eventtap.keyStroke({"ctrl", "shift"}, "tab", 0)
                return true
            elseif keyCode == 35 then -- Taste 'p' -> Search Tabs
                hs.eventtap.keyStroke({"cmd", "shift"}, "a", 0)
                return true
            end
        end

        -- 3. ALLGEMEINE GUI LOGIK (Ctrl -> Cmd / Option)
        if flags.ctrl and not (flags.cmd or flags.alt) then
            -- Navigation
            if ctrlToOptionMap[keyCode] then
                hs.eventtap.keyStroke({"alt"}, ctrlToOptionMap[keyCode], 0)
                return true
            end
            -- Editier-Befehle
            if ctrlToCmdMap[keyCode] then
                local target = ctrlToCmdMap[keyCode]
                if target == "y" then hs.eventtap.keyStroke({"cmd", "shift"}, "z", 0)
                else hs.eventtap.keyStroke({"cmd"}, target, 0) end
                return true
            end
        end

        return false
    end):start()
end

return M