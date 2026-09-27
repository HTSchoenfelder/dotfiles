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
}

return config
