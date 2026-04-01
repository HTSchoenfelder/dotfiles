local config = require("config")
require("hs.ipc")
require("apps")
require("windows")
require("functions")
require("midi")
require("shortcuts")
local launcher = require("launcher")
local linuxshortcuts = require("remapping")

launcher.init()
linuxshortcuts.start()

-- Pathwatcher für automatischen Reload
function reloadConfig(files)
    for _,file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Hammerspoon: Alle Module aktiv 🐧")