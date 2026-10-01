local config = require("config")
local KeyRemapper = require("modules.key_remapper")

local remapping = {}

function remapping.start()
  if not remapping.instance then
    remapping.instance = KeyRemapper.new(config.keyboard):start()
  end
  return remapping.instance
end

function remapping.stop()
  if remapping.instance then
    remapping.instance:stop()
    remapping.instance = nil
  end
end

return remapping
