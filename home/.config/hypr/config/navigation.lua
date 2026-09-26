return {
    modifier = "SUPER + CTRL + ALT",
    stack_key = "F",
    instance_key = "A",
    placement_workspaces = { primary = 1, secondary = 2 },
    placement_modifiers = {
        { key = "Z", screen = "secondary", position = "left" },
        { key = "X", screen = "secondary", position = "right" },
        { key = "C", screen = "primary", position = "left" },
        { key = "V", screen = "primary", position = "right" },
    },
    cycle_rows = 7,
    launch_timeout_ms = 15000,
    applications = {
        { name = "Kitty / Zellij", key = "J", class = "kitty", command = { "env", "START_ZELLIJ=1", "kitty" } },
        { name = "VS Code", key = "K", class = "code", command = { "code" } },
        { name = "Chrome", key = "L", class = "google-chrome", command = { "google-chrome-stable" } },
        { name = "Obsidian", key = "semicolon", class = "obsidian", command = { "obsidian" } },
        { name = "KeePassXC", key = "O", class = "org.keepassxc.KeePassXC", command = { "keepassxc" } },
        { name = "Spotify", key = "U", class = "spotify", command = { "spotify" } },
    },
}
