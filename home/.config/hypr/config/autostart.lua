local home = assert(os.getenv("HOME"), "HOME is not set")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("udiskie --tray")

    -- Keep Synology Drive on X11/XWayland and retain the previous 10 second delay.
    hl.exec_cmd("env QT_QPA_PLATFORM=xcb sh -c 'sleep 10 && exec synology-drive start'")

    hl.exec_cmd([[dconf write /org/gnome/desktop/interface/cursor-theme "'catppuccin-mocha-mauve-cursors'"]])
    hl.exec_cmd("dconf write /org/gnome/desktop/interface/cursor-size 32")

    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("arduino-create-agent")

    -- hl.exec_cmd("spotify_player --daemon")

    hl.exec_cmd(home .. "/.config/hypr/scripts/listen-to-events.sh")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
