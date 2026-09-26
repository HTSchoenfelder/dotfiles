local config = require("config")
local applications = require("apps")
local layout = require("modules.display_layout")
local Registry = require("modules.window_registry")
local WindowChooser = require("modules.window_chooser")
local WindowNavigation = require("modules.window_navigation")
local ApplicationNavigation = require("modules.application_navigation")
local CommaSelection = require("modules.comma_selection")
local HeldKeys = require("modules.held_keys")

local navigation = {}

function navigation.start()
  local settings = config.navigation
  local registry = Registry.new()
  local windowNavigation = WindowNavigation.new(registry, layout, settings)
  local chooser = WindowChooser.new(registry, {rows = settings.chooserRows})
  local applicationNavigation = ApplicationNavigation.new(
    registry,
    windowNavigation,
    chooser,
    settings
  )
  local commaSelection = CommaSelection.new(registry, windowNavigation)
  local heldKeys = HeldKeys.new(config.hyper)

  heldKeys:track(settings.stackKey)
  heldKeys:track(settings.instanceKey)
  windowNavigation:start()

  local function selectionOptions()
    return {
      stack = heldKeys:isDown(settings.stackKey),
      chooseInstance = heldKeys:isDown(settings.instanceKey),
    }
  end

  for _, application in ipairs(applications) do
    hs.hotkey.bind(config.hyper, application.key, function()
      applicationNavigation:activate(application, selectionOptions())
    end)
  end

  hs.hotkey.bind(config.hyper, "m", function()
    windowNavigation:focusNext()
  end)
  hs.hotkey.bind(config.hyper, "n", function()
    windowNavigation:swapPositions()
  end)
  hs.hotkey.bind(config.hyper, "h", function()
    windowNavigation:focusOtherDisplay()
  end)
  hs.hotkey.bind(config.hyper, "w", function()
    local window = hs.window.focusedWindow()
    if registry:isManagedWindow(window) then
      window:close()
    end
  end)
  hs.hotkey.bind(config.hyper, "p", function()
    applicationNavigation:chooseAny(selectionOptions())
  end)

  local function cycleForward()
    commaSelection:cycle(1, {
      stack = heldKeys:isDown(settings.stackKey),
      instancesOnly = heldKeys:isDown(settings.instanceKey),
    })
  end
  local function cycleBackward()
    commaSelection:cycle(-1, {
      stack = heldKeys:isDown(settings.stackKey),
      instancesOnly = heldKeys:isDown(settings.instanceKey),
    })
  end
  hs.hotkey.bind(config.hyper, ",", cycleForward, nil, cycleForward)
  hs.hotkey.bind({"alt", "ctrl", "cmd", "shift"}, ",", cycleBackward, nil, cycleBackward)

  navigation.registry = registry
  navigation.windows = windowNavigation
  navigation.applications = applicationNavigation
end

return navigation
