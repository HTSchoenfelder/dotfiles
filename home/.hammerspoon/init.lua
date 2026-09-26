require("hs.ipc")
require("windows")
require("functions")
require("midi")
require("shortcuts")
local launcher = require("launcher")
local linuxshortcuts = require("remapping")
local navigation = require("navigation")

launcher.init()
linuxshortcuts.start()
navigation.start()

-- Reload automatically after a Lua configuration change.
function reloadConfig(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.alert.show("Hammerspoon ready")
