local config = {}

config.hyper = {"alt", "ctrl", "cmd"}
config.log = hs.logger.new("hammerspoon", "debug")

config.navigation = {
  instanceKey = "f",
  launchTimeoutSeconds = 15,
  launchPollIntervalSeconds = 0.1,
  restoreDelaySeconds = 0.08,
  gap = 5,
  chooserRows = 7,
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
