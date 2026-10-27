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
    if application.key then
      local app = application
      local label = "MainMod + " .. app.key:upper()
      local function activate(mode, chooseInstance)
        applicationNavigation:activate(app, mode, chooseInstance)
      end
      hs.hotkey.bind(config.hyper, app.key, function()
        activate(heldKeys:isDown(settings.otherSlotKey) and "other" or "focused",
          heldKeys:isDown(settings.filterKey))
      end)
      catalog.add("Applications", label, "Focus " .. app.name,
        function() activate("focused", false) end)
      catalog.add("Applications", "MainMod + F + " .. app.key:upper(),
        "Choose " .. app.name .. " window", function() activate("focused", true) end)
      catalog.add("Applications", "MainMod + S + " .. app.key:upper(),
        "Fill other slot with " .. app.name, function() activate("other", false) end)
      catalog.add("Applications", "MainMod + F + S + " .. app.key:upper(),
        "Choose " .. app.name .. " window for other slot",
        function() activate("other", true) end)
    end
  end

  hs.hotkey.bind(config.hyper, "m", function() windowNavigation:focusNext() end)
  hs.hotkey.bind(config.hyper, "n", function() windowNavigation:rotatePositions() end)
  hs.hotkey.bind(config.hyper, "h", function() windowNavigation:focusOtherDisplay() end)
  hs.hotkey.bind(config.hyper, "/", function() windowNavigation:makeFocusedSingle() end)
  hs.hotkey.bind(shifted(config.hyper), "/", function() windowNavigation:enableTwo() end)
  hs.hotkey.bind(config.hyper, "w", function() windowNavigation:closeFocused() end)
  hs.hotkey.bind(config.hyper, "p", function()
    windowNavigation:chooseAny(
      heldKeys:isDown(settings.otherSlotKey) and "other" or "focused",
      heldKeys:isDown(settings.filterKey)
    )
  end)

  local function windowCycle(direction, instancesOnly, mode)
    if instancesOnly == nil then instancesOnly = heldKeys:isDown(settings.filterKey) end
    mode = mode or (heldKeys:isDown(settings.otherSlotKey) and "other" or "focused")
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

  local function windowChoice(mode, filtered)
    return function() windowNavigation:chooseAny(mode, filtered) end
  end
  local function cycleChoice(direction, filtered, mode)
    return function() windowCycle(direction, filtered, mode) end
  end
  catalog.add("Windows", "MainMod + P", "Choose window by last focus",
    windowChoice("focused", false))
  catalog.add("Windows", "MainMod + F + P", "Choose focused application window",
    windowChoice("focused", true))
  catalog.add("Windows", "MainMod + S + P", "Choose window for other slot",
    windowChoice("other", false))
  catalog.add("Windows", "MainMod + F + S + P", "Choose focused application window for other slot",
    windowChoice("other", true))
  catalog.add("Windows", "MainMod + ,", "Adopt windows by last focus",
    cycleChoice(1, false, "focused"))
  catalog.add("Windows", "MainMod + Shift + ,", "Adopt windows backwards",
    cycleChoice(-1, false, "focused"))
  catalog.add("Windows", "MainMod + F + ,", "Adopt application windows",
    cycleChoice(1, true, "focused"))
  catalog.add("Windows", "MainMod + F + Shift + ,", "Adopt application windows backwards",
    cycleChoice(-1, true, "focused"))
  catalog.add("Windows", "MainMod + S + ,", "Adopt windows into other slot",
    cycleChoice(1, false, "other"))
  catalog.add("Windows", "MainMod + S + Shift + ,", "Adopt windows backwards into other slot",
    cycleChoice(-1, false, "other"))
  catalog.add("Windows", "MainMod + F + S + ,", "Adopt application windows into other slot",
    cycleChoice(1, true, "other"))
  catalog.add("Windows", "MainMod + F + S + Shift + ,",
    "Adopt application windows backwards into other slot", cycleChoice(-1, true, "other"))
  catalog.add("Navigation", "MainMod + M", "Focus other slot",
    function() windowNavigation:focusNext() end)
  catalog.add("Windows", "MainMod + N", "Swap slot contents",
    function() windowNavigation:rotatePositions() end)
  catalog.add("Navigation", "MainMod + H", "Focus other display",
    function() windowNavigation:focusOtherDisplay() end)
  catalog.add("Windows", "MainMod + /", "Keep only focused window in layout",
    function() windowNavigation:makeFocusedSingle() end)
  catalog.add("Windows", "MainMod + Shift + /", "Use two slots",
    function() windowNavigation:enableTwo() end)
  catalog.add("Windows", "MainMod + W", "Close focused window",
    function() windowNavigation:closeFocused() end)

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
