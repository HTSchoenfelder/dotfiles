local config = {}

config.hyper = {"alt", "ctrl", "cmd"}
config.log = hs.logger.new("hammerspoon", "debug")

config.navigation = {
  stackKey = "f",
  instanceKey = "a",
  launchTimeoutSeconds = 15,
  launchPollIntervalSeconds = 0.1,
  restoreDelaySeconds = 0.08,
  chooserRows = 7,
  applications = {
    {key = "j", name = "kitty", bundleID = "net.kovidgoyal.kitty"},
    {key = "k", name = "Code", bundleID = "com.microsoft.VSCode"},
    {key = "l", name = "Google Chrome", bundleID = "com.google.Chrome"},
    {key = ";", name = "Obsidian", bundleID = "md.obsidian"},
    {key = "o", name = "KeePassXC", bundleID = "org.keepassxc.keepassxc"},
    {key = "u", name = "Spotify", bundleID = "com.spotify.client"},
  },
}

return config
