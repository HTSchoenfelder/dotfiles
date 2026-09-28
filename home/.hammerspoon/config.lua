local config = {}

config.hyper = {"alt", "ctrl", "cmd"}
config.log = hs.logger.new("hammerspoon", "debug")

config.navigation = {
  stackKey = "f",
  instanceKey = "a",
  launchTimeoutSeconds = 15,
  launchPollIntervalSeconds = 0.1,
  chooserRows = 7,
  workspaces = {
    terminal = "1",
    display = "2",
    parking = "10",
    overlays = "99",
  },
}

config.aerospace = {
  executableCandidates = {
    "/opt/homebrew/bin/aerospace",
    "/usr/local/bin/aerospace",
  },
}

config.paths = {
  repository = os.getenv("HOME") .. "/dotfiles",
  kittyApp = "/Applications/Nix Apps/kitty.app",
}

config.chooser = {
  rows = config.navigation.chooserRows,
  width = 40,
}

return config
