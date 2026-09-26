local process = require("lib.process")
local screenshots = {}

function screenshots.capture_region()
    process.spawn({ "hyprshot", "--mode", "region" })
end

function screenshots.capture_active_output()
    process.spawn({ "hyprshot", "--mode", "output", "--mode", "active" })
end

return screenshots
