local config = require("config")
local applications = require("apps")
local ApplicationNavigation = require("modules.application_navigation")
local CommaSelection = require("modules.comma_selection")
local HeldKeys = require("modules.held_keys")
local WindowChooser = require("modules.window_chooser")
local WindowNavigation = require("modules.window_navigation")
local catalog = require("shortcut_catalog")

local navigation = {}

function navigation.start()
  local settings = config.navigation
  local windowNavigation = WindowNavigation.new(settings)
  local chooser = WindowChooser.new({rows = settings.chooserRows})
  local applicationNavigation = ApplicationNavigation.new(settings, chooser, windowNavigation)
  local commaSelection = CommaSelection.new(windowNavigation)
  local heldKeys = HeldKeys.new(config.hyper)

  for _, placement in ipairs(settings.placementModifiers) do
    heldKeys:track(placement.key)
  end
  heldKeys:track(settings.instanceKey)

  local function selectedPlacement()
    for _, placement in ipairs(settings.placementModifiers) do
      if heldKeys:isDown(placement.key) then
        return placement
      end
    end
    return settings.defaultPlacement
  end

  for _, application in ipairs(applications) do
    hs.hotkey.bind(config.hyper, application.key, function()
      applicationNavigation:activate(
        application,
        selectedPlacement(),
        heldKeys:isDown(settings.instanceKey)
      )
    end)
    catalog.add("Applications", "MainMod + " .. application.key:upper(), "Focus " .. application.name)
  end

  catalog.add("Applications", "MainMod + A + App", "Select application window")
  for _, placement in ipairs(settings.placementModifiers) do
    local display = placement.screen == "primary" and "primary" or "secondary"
    catalog.add(
      "Applications",
      "MainMod + " .. placement.key:upper() .. " + App",
      "Place on " .. display .. " " .. placement.position
    )
  end

  hs.hotkey.bind(config.hyper, "m", function() windowNavigation:focusNext() end)
  hs.hotkey.bind(config.hyper, "n", function() windowNavigation:swapPositions() end)
  hs.hotkey.bind(config.hyper, "h", function() windowNavigation:focusOtherDisplay() end)
  hs.hotkey.bind(config.hyper, "w", function() windowNavigation:closeFocused() end)
  hs.hotkey.bind(config.hyper, "p", function() applicationNavigation:chooseAny() end)

  local function cycleForward()
    commaSelection:cycle(1, heldKeys:isDown(settings.instanceKey))
  end
  local function cycleBackward()
    commaSelection:cycle(-1, heldKeys:isDown(settings.instanceKey))
  end
  hs.hotkey.bind(config.hyper, ",", cycleForward, nil, cycleForward)
  hs.hotkey.bind({"alt", "ctrl", "cmd", "shift"}, ",", cycleBackward, nil, cycleBackward)

  catalog.add("Windows", "MainMod + P", "Choose window")
  catalog.add("Windows", "MainMod + ,", "Cycle windows forward")
  catalog.add("Windows", "MainMod + Shift + ,", "Cycle windows backward")
  catalog.add("Windows", "MainMod + A + ,", "Cycle application windows")
  catalog.add("Navigation", "MainMod + M", "Focus next window")
  catalog.add("Navigation", "MainMod + N", "Swap window positions")
  catalog.add("Navigation", "MainMod + H", "Focus other display")
  catalog.add("Windows", "MainMod + W", "Close focused window")

  navigation.applications = applicationNavigation
  navigation.commaSelection = commaSelection
  navigation.heldKeys = heldKeys
  navigation.windows = windowNavigation
end

return navigation
