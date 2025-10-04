local M = {}
local config = require("config")
function M.init()
  hs.loadSpoon("Seal")
  spoon.Seal:loadPlugins({"useractions", "apps"})
  spoon.Seal.plugins.useractions.actions = {
    ["Hammerspoon docs webpage"] = {
      url = "http://hammerspoon.org/docs/",
      icon = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon),
      description = "Open Hammerspoon documentation",
    },
    ["Translate using Leo"] = {
      url = "http://dict.leo.org/ende/index_de.html#/search=${query}",
      icon = 'favicon',
      keyword = "leo",
    },
    ["Tell me something"] = {
      keyword = "tellme",
      fn = function(str) hs.alert.show(str) end,
    },
    ["Reload Hammerspoon config"] = {
      keyword = "reload",
      fn = function() hs.reload() end,
    }
  }

  hs.hotkey.bind(config.hyper, "R", function()
    spoon.Seal:toggle()
  end)

  spoon.Seal:start()

end

return M