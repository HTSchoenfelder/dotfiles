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

config.keyboard = {
  chromeBundleID = "com.google.Chrome",
  vsCodeBundleID = "com.microsoft.VSCode",
  terminalBundleIDs = {
    "net.kovidgoyal.kitty",
    "com.apple.Terminal",
    "com.googlecode.iterm2",
  },
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

config.rodecaster = {
  deviceName = "RODECaster Pro II",
  channel = 0,
  controllerNumber = 27,
  mutedValue = 1,
  unmutedValue = 0,
  echoSuppressionSeconds = 0.3,
  settingsKey = "dotfiles.rodecaster.assumedMuted",
  overlay = {
    width = 200,
    height = 50,
    bottomMargin = 80,
    radius = 10,
    textSize = 22,
    fillColor = {hex = "#f38ba8", alpha = 0.9},
    textColor = {hex = "#1e1e2e"},
  },
}

return config
