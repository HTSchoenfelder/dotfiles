local config = require("config")
local applications = require("apps")
local AerospaceClient = require("modules.aerospace_client")
local ApplicationNavigation = require("modules.application_navigation")
local Chooser = require("modules.chooser")
local CommaSelection = require("modules.comma_selection")
local HeldKeys = require("modules.held_keys")
local LayoutOrchestrator = require("modules.layout_orchestrator")
local RequestGate = require("modules.request_gate")
local WindowHistory = require("modules.window_history")
local WindowNavigation = require("modules.window_navigation")
local WindowRepository = require("modules.window_repository")
local WorkspaceNavigation = require("modules.workspace_navigation")
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
  local client = AerospaceClient.new(config.aerospace)
  local gate = RequestGate.new()
  local history = WindowHistory.new()
  history:start()
  local repository = WindowRepository.new(client, history)
  local orchestrator = LayoutOrchestrator.new(client, repository, gate, settings.workspaces)
  local applicationNavigation = ApplicationNavigation.new({
    client = client,
    repository = repository,
    orchestrator = orchestrator,
    chooserFactory = chooserFactory,
    gate = gate,
    workspaces = settings.workspaces,
    launchTimeoutSeconds = settings.launchTimeoutSeconds,
    launchPollIntervalSeconds = settings.launchPollIntervalSeconds,
  })
  local windowNavigation = WindowNavigation.new({
    client = client,
    repository = repository,
    orchestrator = orchestrator,
    chooserFactory = chooserFactory,
    gate = gate,
    workspaces = settings.workspaces,
  })
  local workspaceNavigation = WorkspaceNavigation.new({
    client = client,
    gate = gate,
    workspaces = settings.workspaces,
  })
  local commaSelection = CommaSelection.new(chooserFactory)
  local heldKeys = HeldKeys.new(config.hyper)

  heldKeys:track(settings.stackKey)
  heldKeys:track(settings.instanceKey)

  local function mode()
    return heldKeys:isDown(settings.stackKey) and "stack" or "single"
  end

  for _, application in ipairs(applications) do
    hs.hotkey.bind(config.hyper, application.key, function()
      applicationNavigation:activate(
        application,
        mode(),
        heldKeys:isDown(settings.instanceKey)
      )
    end)
    catalog.add("Applications", "MainMod + " .. application.key:upper(), "Focus " .. application.name)
  end

  catalog.add("Applications", "MainMod + A + App", "Select application window")
  catalog.add("Applications", "MainMod + F + App", "Add application to stack")

  hs.hotkey.bind(config.hyper, "m", function() windowNavigation:focusNext() end)
  hs.hotkey.bind(config.hyper, "n", function() windowNavigation:rotatePositions() end)
  hs.hotkey.bind(config.hyper, "h", function() workspaceNavigation:switchPrimary() end)
  hs.hotkey.bind(config.hyper, "w", function() windowNavigation:closeFocused() end)
  hs.hotkey.bind(config.hyper, "p", function() windowNavigation:chooseAny(mode()) end)

  local function windowCycle(direction)
    local kind = heldKeys:isDown(settings.instanceKey) and "application_windows" or "windows"
    local currentSession = commaSelection.session
    local context = {}
    local generation = currentSession and currentSession.kind == kind
      and currentSession.generation or gate:next()
    local selectionMode = currentSession and currentSession.kind == kind
      and currentSession.selectionMode or mode()
    commaSelection:cycle(kind, direction, {
      generation = generation,
      load = function(done)
        windowNavigation:commaItems(kind == "application_windows", function(items, focused)
          local session = commaSelection.session
          if session and session.kind == kind then
            session.currentID = focused and focused.id
            context.workspace = focused and focused.workspace or settings.workspaces.terminal
          end
          done(items)
        end)
      end,
      onSelect = function(item)
        windowNavigation:activateComma(item.record, selectionMode, context.workspace, generation)
      end,
    })
    if commaSelection.session then
      commaSelection.session.generation = generation
      commaSelection.session.selectionMode = selectionMode
    end
  end

  local function workspaceCycle(direction)
    local kind = "workspaces"
    local currentSession = commaSelection.session
    local generation = currentSession and currentSession.kind == kind
      and currentSession.generation or gate:next()
    commaSelection:cycle(kind, direction, {
      generation = generation,
      load = function(done)
        workspaceNavigation:commaItems(function(items, currentID)
          local session = commaSelection.session
          if session and session.kind == kind then session.currentID = currentID end
          done(items)
        end)
      end,
      onSelect = function(item) workspaceNavigation:focus(item.workspace, generation) end,
    })
    if commaSelection.session then commaSelection.session.generation = generation end
  end

  hs.hotkey.bind(config.hyper, ",", function() windowCycle(1) end, nil, function() windowCycle(1) end)
  hs.hotkey.bind(shifted(config.hyper), ",", function() windowCycle(-1) end, nil, function() windowCycle(-1) end)
  hs.hotkey.bind(config.hyper, "g", function() workspaceCycle(1) end, nil, function() workspaceCycle(1) end)
  hs.hotkey.bind(shifted(config.hyper), "g", function() workspaceCycle(-1) end, nil, function() workspaceCycle(-1) end)

  catalog.add("Windows", "MainMod + P", "Choose window by last focus")
  catalog.add("Windows", "MainMod + F + P", "Choose window and add it to stack")
  catalog.add("Windows", "MainMod + ,", "Cycle windows by last focus")
  catalog.add("Windows", "MainMod + Shift + ,", "Cycle windows backwards")
  catalog.add("Windows", "MainMod + A + ,", "Cycle application windows")
  catalog.add("Windows", "MainMod + F + ,", "Cycle and add selected window to stack")
  catalog.add("Navigation", "MainMod + M", "Focus next tiled window")
  catalog.add("Windows", "MainMod + N", "Rotate window positions")
  catalog.add("Navigation", "MainMod + H", "Switch between workspaces 1 and 2")
  catalog.add("Navigation", "MainMod + G", "Cycle workspaces by last focus")
  catalog.add("Navigation", "MainMod + Shift + G", "Cycle workspaces backwards")
  catalog.add("Windows", "MainMod + W", "Close focused window")

  navigation.services = {
    applications = applicationNavigation,
    chooserFactory = chooserFactory,
    client = client,
    commaSelection = commaSelection,
    gate = gate,
    history = history,
    repository = repository,
    windows = windowNavigation,
    workspaces = workspaceNavigation,
    workspaceNames = settings.workspaces,
  }
  return navigation.services
end

return navigation
