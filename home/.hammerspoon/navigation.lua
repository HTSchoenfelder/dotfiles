local config = require("config")
local applications = require("apps")
local ApplicationNavigation = require("modules.application_navigation")
local Chooser = require("modules.chooser")
local CommaSelection = require("modules.comma_selection")
local HeldKeys = require("modules.held_keys")
local LayoutOrchestrator = require("modules.layout_orchestrator")
local LayoutBorders = require("modules.layout_borders")
local RequestGate = require("modules.request_gate")
local WindowHistory = require("modules.window_history")
local WindowNavigation = require("modules.window_navigation")
local WindowRepository = require("modules.window_repository")
local catalog = require("shortcut_catalog")

local navigation = {}

local function shifted(modifiers)
  local result = {}
  for _, modifier in ipairs(modifiers) do result[#result + 1] = modifier end
  result[#result + 1] = "shift"
  return result
end

function navigation.start()
  local settings = config.navigation
  local function chooserFactory() return Chooser.new(config.chooser) end
  local gate = RequestGate.new()
  local history = WindowHistory.new()
  history:start()
  local repository = WindowRepository.new(history)
  local orchestrator = LayoutOrchestrator.new(repository, gate, settings)
  local layoutBorders = LayoutBorders.new(
    orchestrator,
    config.appearance.layoutBorders
  ):start()
  local applicationNavigation = ApplicationNavigation.new({
    repository = repository,
    orchestrator = orchestrator,
    chooserFactory = chooserFactory,
    gate = gate,
    launchTimeoutSeconds = settings.launchTimeoutSeconds,
    launchPollIntervalSeconds = settings.launchPollIntervalSeconds,
  })
  local windowNavigation = WindowNavigation.new({
    repository = repository,
    orchestrator = orchestrator,
    chooserFactory = chooserFactory,
    gate = gate,
  })
  local commaSelection = CommaSelection.new(chooserFactory)
  local heldKeys = HeldKeys.new(config.hyper)

  heldKeys:track(settings.instanceKey)
  heldKeys:track(settings.monitorKey)

  for _, application in ipairs(applications) do
    hs.hotkey.bind(config.hyper, application.key, function()
      applicationNavigation:activate(
        application,
        "single",
        heldKeys:isDown(settings.instanceKey)
      )
    end)
    hs.hotkey.bind(shifted(config.hyper), application.key, function()
      applicationNavigation:activate(
        application,
        "stack",
        heldKeys:isDown(settings.instanceKey)
      )
    end)
    catalog.add("Applications", "MainMod + " .. application.key:upper(), "Focus " .. application.name)
  end

  catalog.add("Applications", "MainMod + F + App", "Select application window")
  catalog.add("Applications", "MainMod + Shift + App", "Add application to stack")

  hs.hotkey.bind(config.hyper, "m", function() windowNavigation:focusNext() end)
  hs.hotkey.bind(config.hyper, "n", function() windowNavigation:rotatePositions() end)
  hs.hotkey.bind(config.hyper, "h", function()
    if heldKeys:isDown(settings.monitorKey) then
      windowNavigation:moveFocusedToOtherDisplay("stack")
    else
      windowNavigation:focusOtherDisplay()
    end
  end)
  hs.hotkey.bind(config.hyper, "/", function()
    if heldKeys:isDown(settings.monitorKey) then
      windowNavigation:moveFocusedToOtherDisplay("single")
    else
      windowNavigation:makeFocusedSingle()
    end
  end)
  hs.hotkey.bind(config.hyper, "w", function() windowNavigation:closeFocused() end)
  hs.hotkey.bind(config.hyper, "p", function() windowNavigation:chooseAny("single") end)
  hs.hotkey.bind(shifted(config.hyper), "p", function() windowNavigation:chooseAny("stack") end)

  local function windowCycle(direction)
    local kind = heldKeys:isDown(settings.instanceKey) and "application_windows" or "windows"
    local currentSession = commaSelection.session
    local generation = currentSession and currentSession.kind == kind
      and currentSession.generation or gate:next()
    commaSelection:cycle(kind, direction, {
      generation = generation,
      load = function(done)
        windowNavigation:commaItems(kind == "application_windows", function(items, focused)
          local session = commaSelection.session
          if session and session.kind == kind then
            session.currentID = focused and focused.id
          end
          done(items)
        end)
      end,
      onSelect = function(item)
        windowNavigation:focusComma(item.record, generation)
      end,
    })
    if commaSelection.session then commaSelection.session.generation = generation end
  end

  hs.hotkey.bind(config.hyper, ",", function() windowCycle(1) end, nil, function() windowCycle(1) end)
  hs.hotkey.bind(shifted(config.hyper), ",", function() windowCycle(-1) end, nil,
    function() windowCycle(-1) end)

  catalog.add("Windows", "MainMod + P", "Choose window by last focus")
  catalog.add("Windows", "MainMod + Shift + P", "Choose window and add it to stack")
  catalog.add("Windows", "MainMod + ,", "Focus windows by last focus")
  catalog.add("Windows", "MainMod + Shift + ,", "Focus windows backwards")
  catalog.add("Windows", "MainMod + F + ,", "Focus application windows")
  catalog.add("Navigation", "MainMod + M", "Focus next layout window")
  catalog.add("Windows", "MainMod + N", "Rotate window positions")
  catalog.add("Navigation", "MainMod + H", "Focus other display")
  catalog.add("Windows", "MainMod + /", "Keep only focused window in layout")
  catalog.add("Windows", "MainMod + G + /", "Move window to other display and replace layout")
  catalog.add("Windows", "MainMod + G + H", "Move window to other display and add to layout")
  catalog.add("Windows", "MainMod + W", "Close focused window")

  navigation.services = {
    applications = applicationNavigation,
    chooserFactory = chooserFactory,
    commaSelection = commaSelection,
    gate = gate,
    history = history,
    layoutBorders = layoutBorders,
    orchestrator = orchestrator,
    repository = repository,
    windows = windowNavigation,
  }
  return navigation.services
end

return navigation
