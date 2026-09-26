local process = require("lib.process")

-- Remaining session tools start once. Dunst, Polkit and portals belong to systemd/D-Bus.
hl.on("hyprland.start", function()
    local commands = {
        { "waybar" },
        { "hyprpaper" },
        { "hypridle" },
        { "clipse", "-listen" },
        { "udiskie", "--tray" },
        { "blueman-applet" },
        { "nm-applet" },
        { "arduino-create-agent" },
    }
    for _, command in ipairs(commands) do process.spawn(command) end
end)
