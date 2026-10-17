local runtime = os.getenv("XDG_RUNTIME_DIR")
local instance = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")

return {
    slot_state_file = runtime and instance and (runtime .. "/hypr-slots-" .. instance .. ".tsv") or nil,
    modifier = "SUPER + CTRL + ALT",
    filter_key = "F",
    other_slot_key = "S",
    cycle_rows = 7,
    launch_timeout_ms = 15000,
    applications = {
        { id = "terminal", name = "Kitty / Zellij", key = "J", class = "kitty", command = { "env", "START_ZELLIJ=1", "kitty" } },
        { id = "code", name = "VS Code", key = "K", class = "code", command = { "code" } },
        { id = "chrome", name = "Chrome", key = "L", class = "google-chrome", command = { "google-chrome-stable" } },
        {
            id = "chat",
            name = "Google Chat",
            class = "chrome-chat.google.com__-Default",
            command = { "google-chrome-stable", "--profile-directory=Default", "--app=https://chat.google.com/" },
        },
        {
            id = "meet",
            name = "Google Meet",
            class = "chrome-meet.google.com__-Default",
            command = { "google-chrome-stable", "--profile-directory=Default", "--app=https://meet.google.com/" },
        },
        {
            id = "gmail",
            name = "Gmail",
            class = "chrome-mail.google.com__-Default",
            command = { "google-chrome-stable", "--profile-directory=Default", "--app=https://mail.google.com/" },
        },
        {
            id = "calendar",
            name = "Google Calendar",
            class = "chrome-calendar.google.com__-Default",
            command = { "google-chrome-stable", "--profile-directory=Default", "--app=https://calendar.google.com/" },
        },
        { id = "obsidian", name = "Obsidian", key = "semicolon", class = "obsidian", command = { "obsidian" } },
        { id = "keepassxc", name = "KeePassXC", key = "O", class = "org.keepassxc.KeePassXC", command = { "keepassxc" } },
        { id = "spotify", name = "Spotify", class = "spotify", command = { "spotify" } },
    },
    application_groups = {
        { key = "I", name = "Chat / Meet", applications = { "chat", "meet" } },
        { key = "U", name = "Mail / Calendar", applications = { "gmail", "calendar" } },
    },
}
