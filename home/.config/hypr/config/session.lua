local process = require("lib.process")

-- Compositor-specific tools stay here; general session daemons belong to NixOS.
-- Reloads do not restart these processes or resume a paused idle daemon.
hl.on("hyprland.start", function()
    local commands = {
        { "hyprpaper" },
        { "hypridle" },
    }
    for _, command in ipairs(commands) do process.spawn(command) end
end)
