require("hs.ipc")
require("functions")

local config = require("config")
local Chooser = require("modules.chooser")
local Launcher = require("launcher")
local navigation = require("navigation")
local remapping = require("remapping")
local shortcutCatalog = require("shortcut_catalog")
local shortcuts = require("shortcuts")

local services = navigation.start()
remapping.start()

local launcher = Launcher.new({
  chooserFactory = function() return Chooser.new(config.chooser) end,
  modifiers = config.hyper,
  gate = services.gate,
})
launcher:start()
shortcuts.start(services)
shortcutCatalog.start(config.hyper, services.chooserFactory)

local function reloadConfig(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then hs.reload(); return end
  end
end

configWatcher = hs.pathwatcher.new(hs.configdir, reloadConfig):start()
