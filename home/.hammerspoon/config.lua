local config = {}

config.hyper = {"alt", "ctrl", "cmd"}
config.log = hs.logger.new("hammerspoon", "debug")

config.navigation = {
  instanceKey = "f",
  monitorKey = "g",
  launchTimeoutSeconds = 15,
  launchPollIntervalSeconds = 0.1,
  restoreDelaySeconds = 0.08,
  validationDelaySeconds = 0.08,
  frameTolerance = 2,
  gap = 5,
  chooserRows = 7,
}

config.paths = {
  repository = os.getenv("HOME") .. "/dotfiles",
  kittyApp = "/Applications/Nix Apps/kitty.app",
  screenshots = os.getenv("HOME") .. "/screenshots",
}

config.chooser = {
  dark = true,
  foregroundColor = {hex = "#cdd6f4"},
  rows = config.navigation.chooserRows,
  searchSubText = true,
  showWindowTitles = true,
  secondaryColor = {hex = "#a6adc8"},
  width = 40,
}

config.appearance = {
  layoutBorders = {
    enabled = true,
    focusColor = {hex = "#a6e3a1"},
    layoutColor = {hex = "#f5c2e7"},
    offset = 2,
    radius = 12,
    width = 4.5,
  },
}

return config
