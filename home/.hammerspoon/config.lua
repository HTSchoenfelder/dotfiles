local config = {}

config.hyper = {"alt", "ctrl", "cmd"}
config.log = hs.logger.new("hammerspoon", "debug")

config.navigation = {
  instanceKey = "a",
  launchTimeoutSeconds = 15,
  launchPollIntervalSeconds = 0.1,
  restoreDelaySeconds = 0.08,
  chooserRows = 7,
  defaultPlacement = {screen = "primary", position = "full"},
  placementModifiers = {
    {key = "f", screen = "secondary", position = "full"},
    {key = "z", screen = "secondary", position = "left"},
    {key = "x", screen = "secondary", position = "right"},
    {key = "c", screen = "primary", position = "left"},
    {key = "v", screen = "primary", position = "right"},
  },
}

return config
