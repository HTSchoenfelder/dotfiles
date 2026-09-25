local user_home = assert(os.getenv("HOME"), "HOME is not set")

hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("HYPRCURSOR_SIZE", "28")

hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("XCURSOR_SIZE", "28")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_CONFIG_HOME", user_home .. "/.config/")

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

hl.env("GTK_USE_PORTAL", "1")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("GTK_FONT_NAME", "Agave Nerd Font")

hl.env("GDK_BACKEND", "wayland")

hl.env("HYPRSHOT_DIR", user_home .. "/screenshots")
