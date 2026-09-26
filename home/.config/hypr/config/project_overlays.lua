return {
    workspace = "special:project-overlays",
    launch_timeout_ms = 10000,
    settle_delay_ms = 30,
    settle_attempts = 10,
    tools = {
        terminal = { command = { "zsh" }, title = "Terminal" },
        editor = { command = { "nvim" }, title = "Editor" },
        git = { command = { "lazygit" }, title = "Git" },
    },
}
