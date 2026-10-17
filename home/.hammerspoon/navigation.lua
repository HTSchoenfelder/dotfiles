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
  local orchestrator = LayoutOrchestrator.new(repository, gate, settings):start()
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

  heldKeys:track(settings.filterKey)
  heldKeys:track(settings.otherSlotKey)

  for _, application in ipairs(applications) do
    hs.hotkey.bind(config.hyper, application.key, function()
      applicationNavigation:activate(
        application,
        heldKeys:isDown(settings.otherSlotKey) and "other" or "focused",
        heldKeys:isDown(settings.filterKey)
      )
    end)
    catalog.add("Applications", "MainMod + " .. application.key:upper(), "Focus " .. application.name)
  end

  catalog.add("Applications", "MainMod + F + App", "Select application window")
  catalog.add("Applications", "MainMod + S + App", "Fill other slot")
  catalog.add("Applications", "MainMod + F + S + App", "Select application window for other slot")

  hs.hotkey.bind(config.hyper, "m", function() windowNavigation:focusNext() end)
  hs.hotkey.bind(config.hyper, "n", function() windowNavigation:rotatePositions() end)
  hs.hotkey.bind(config.hyper, "h", function()
    windowNavigation:focusOtherDisplay()
  end)
  hs.hotkey.bind(config.hyper, "/", function()
    windowNavigation:makeFocusedSingle()
  end)
  hs.hotkey.bind(shifted(config.hyper), "/", function() windowNavigation:enableTwo() end)
  hs.hotkey.bind(config.hyper, "w", function() windowNavigation:closeFocused() end)
  hs.hotkey.bind(config.hyper, "p", function()
    windowNavigation:chooseAny(
      heldKeys:isDown(settings.otherSlotKey) and "other" or "focused",
      heldKeys:isDown(settings.filterKey)
    )
  end)

  local function windowCycle(direction)
    local instancesOnly = heldKeys:isDown(settings.filterKey)
    local mode = heldKeys:isDown(settings.otherSlotKey) and "other" or "focused"
    local kind = (instancesOnly and "application_windows" or "windows") .. ":" .. mode
    local currentSession = commaSelection.session
    local generation = currentSession and currentSession.kind == kind
      and currentSession.generation or gate:next()
    local request = currentSession and currentSession.kind == kind
      and currentSession.request or orchestrator:capture(mode, generation)
    commaSelection:cycle(kind, direction, {
      generation = generation,
      load = function(done)
        windowNavigation:commaItems(instancesOnly, function(items, focused)
          local session = commaSelection.session
          if session and session.kind == kind then
            session.currentID = focused and focused.id
          end
          done(items)
        end)
      end,
      onSelect = function(item)
        windowNavigation:acceptComma(item.record, request)
      end,
    })
    if commaSelection.session then
      commaSelection.session.generation = generation
      commaSelection.session.request = request
    end
  end

  hs.hotkey.bind(config.hyper, ",", function() windowCycle(1) end, nil, function() windowCycle(1) end)
  hs.hotkey.bind(shifted(config.hyper), ",", function() windowCycle(-1) end, nil,
    function() windowCycle(-1) end)

  catalog.add("Windows", "MainMod + P", "Choose window by last focus")
  catalog.add("Windows", "MainMod + F + P", "Choose focused application window")
  catalog.add("Windows", "MainMod + S + P", "Choose window for other slot")
  catalog.add("Windows", "MainMod + F + S + P", "Choose focused application window for other slot")
  catalog.add("Windows", "MainMod + ,", "Adopt windows by last focus")
  catalog.add("Windows", "MainMod + Shift + ,", "Adopt windows backwards")
  catalog.add("Windows", "MainMod + F + ,", "Adopt application windows")
  catalog.add("Windows", "MainMod + F + Shift + ,", "Adopt application windows backwards")
  catalog.add("Windows", "MainMod + S + ,", "Adopt windows into other slot")
  catalog.add("Windows", "MainMod + S + Shift + ,", "Adopt windows backwards into other slot")
  catalog.add("Windows", "MainMod + F + S + ,", "Adopt application windows into other slot")
  catalog.add("Windows", "MainMod + F + S + Shift + ,", "Adopt application windows backwards into other slot")
  catalog.add("Navigation", "MainMod + M", "Focus other slot")
  catalog.add("Windows", "MainMod + N", "Swap slot contents")
  catalog.add("Navigation", "MainMod + H", "Focus other display")
  catalog.add("Windows", "MainMod + /", "Keep only focused window in layout")
  catalog.add("Windows", "MainMod + Shift + /", "Use two slots")
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
