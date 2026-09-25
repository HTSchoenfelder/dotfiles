local process = require("lib.process")

-- Session ownership is unchanged; reloads must not start another copy of these processes.
hl.on("hyprland.start", function()
    local commands = {
        { "waybar" },
        { "dunst" },
        { "hyprpaper" },
        { "hypridle" },
        { "clipse", "-listen" },
        { "udiskie", "--tray" },
        { "dconf", "write", "/org/gnome/desktop/interface/cursor-theme", "'catppuccin-mocha-mauve-cursors'" },
        { "dconf", "write", "/org/gnome/desktop/interface/cursor-size", "32" },
        { "blueman-applet" },
        { "nm-applet" },
        { "arduino-create-agent" },
        { "dbus-update-activation-environment", "--systemd", "--all" },
    }
    for _, command in ipairs(commands) do process.spawn(command) end
end)
