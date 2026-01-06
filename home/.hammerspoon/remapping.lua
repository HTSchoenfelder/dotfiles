local M = {}

local terminalApps = {
    ["net.kovidgoyal.kitty"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true
}

local ctrlToCmdMap = {
    [0] = "a",
    [8] = "c",
    [9] = "v",
    [7] = "x",
    [3] = "f",
    [6] = "z",
    [1] = "s",
    [13] = "w",
    [16] = "y"
}

local ctrlToOptionMap = {
    [123] = "left",
    [124] = "right",
    [51] = "delete",
    [117] = "forwarddelete"
}

M.start = function()
    M.tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        local app = hs.application.frontmostApplication()
        if not app then
            return false
        end

        local bundleID = app:bundleID()
        local isTerm = terminalApps[bundleID]
        local isChrome = (bundleID == "com.google.Chrome")
        local isVsCode = (bundleID == "com.microsoft.VSCode")

        -- 1. TERMINAL PRIORITÄT
        if isTerm then
            if flags.ctrl and flags.shift and not (flags.cmd or flags.alt) then
                if keyCode == 8 then
                    hs.eventtap.keyStroke({"cmd"}, "c", 0);
                    return true
                end
                if keyCode == 9 then
                    hs.eventtap.keyStroke({"cmd"}, "v", 0);
                    return true
                end
                if keyCode == 6 then
                    hs.eventtap.keyStroke({"cmd", "shift"}, "z", 0);
                    return true
                end
            end
            return false
        end

        if isVsCode then
            return false
        end

        -- 2. CHROME SPEZIAL LOGIK
        if isChrome and flags.ctrl and not (flags.cmd or flags.alt or flags.shift) then
            if keyCode == 40 then
                hs.eventtap.keyStroke({"ctrl"}, "tab", 0);
                return true
            elseif keyCode == 38 then
                hs.eventtap.keyStroke({"ctrl", "shift"}, "tab", 0);
                return true
            elseif keyCode == 35 then
                hs.eventtap.keyStroke({"cmd", "shift"}, "a", 0);
                return true
            end
        end

        -- 3. ALLGEMEINE GUI LOGIK
        if flags.ctrl and not (flags.cmd or flags.alt) then
            -- Navigation
            if ctrlToOptionMap[keyCode] then
                hs.eventtap.keyStroke({"alt"}, ctrlToOptionMap[keyCode], 0)
                return true
            end

            -- Editier-Befehle
            if ctrlToCmdMap[keyCode] then
                local target = ctrlToCmdMap[keyCode]
                local mods = {"cmd"}
                if flags.shift then
                    table.insert(mods, "shift")
                end

                if target == "y" then
                    hs.eventtap.keyStroke({"cmd", "shift"}, "z", 0)
                else
                    hs.eventtap.keyStroke(mods, target, 0)
                end
                return true
            end

            return false
        end

        return false
    end):start()
end

return M
