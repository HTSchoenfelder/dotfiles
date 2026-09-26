local process = require("lib.process")
local screenshots = {}

function screenshots.capture_region()
    process.spawn({ "hyprshot", "--mode", "region" })
end

function screenshots.capture_active_output()
    process.spawn({ "hyprshot", "--mode", "output", "--mode", "active" })
end

function screenshots.capture_active_window()
    if hl.get_active_window() then
        process.spawn({ "hyprshot", "--mode", "window", "--mode", "active" })
    end
end

return screenshots
