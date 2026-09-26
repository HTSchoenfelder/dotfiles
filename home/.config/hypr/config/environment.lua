local user_home = assert(os.getenv("HOME"), "HOME is not set")

hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("HYPRCURSOR_SIZE", "28")

hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors", true)
hl.env("XCURSOR_SIZE", "28", true)

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- Hyprland owns XDG session identity; NixOS owns toolkit plugins and themes.
hl.env("QT_QPA_PLATFORM", "wayland;xcb", true)
hl.env("GDK_BACKEND", "wayland,x11,*", true)

hl.env("HYPRSHOT_DIR", user_home .. "/screenshots")
