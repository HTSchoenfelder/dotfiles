local WindowRepository = require("modules.window_repository")

local WindowNavigation = {}
WindowNavigation.__index = WindowNavigation

local function windowChoice(record)
  local title = record.title ~= "" and record.title or record.appName
  return {text = record.appName .. " — " .. title, id = record.id, record = record}
end

function WindowNavigation.new(options)
  options.allScreens = options.allScreens or function() return hs.screen.allScreens() end
  return setmetatable(options, WindowNavigation)
end

function WindowNavigation:_records(callback)
  self.repository:listAll(function(records) callback(records or {}) end)
end

function WindowNavigation:_request(mode, focused, generation)
  return {
    anchorID = focused and focused.id,
    generation = generation,
    mode = mode,
    screen = focused and focused.screen or self.orchestrator:activeScreen(),
  }
end

function WindowNavigation:chooseAny(mode)
  local generation = self.gate:next()
  self:_records(function(records)
    if not self.gate:isCurrent(generation) then return end
    local focused = self.repository:focusedRecord(records)
    local choices = {}
    for _, record in ipairs(self.repository:orderedByHistory(records)) do
      choices[#choices + 1] = windowChoice(record)
    end
    local request = self:_request(mode, focused, generation)
    local chooser = self.chooserFactory()
    chooser:show(choices, function(selected)
      if selected and self.gate:isCurrent(generation) then
        self.orchestrator:activate(selected.record, request)
      end
    end, request.screen)
  end)
end

function WindowNavigation:commaItems(instancesOnly, callback)
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    local ordered = self.repository:orderedByHistory(records)
    local items = {}
    for _, record in ipairs(ordered) do
      if not instancesOnly or (focused and record.bundleID == focused.bundleID) then
        items[#items + 1] = windowChoice(record)
      end
    end
    callback(items, focused)
  end)
end

function WindowNavigation:activateComma(record, request)
  if self.gate:isCurrent(request.generation) then
    self.orchestrator:activate(record, request)
  end
end

function WindowNavigation:focusNext()
  self.gate:next()
  self.orchestrator:focusNext()
end

function WindowNavigation:rotatePositions()
  self.gate:next()
  self.orchestrator:rotatePositions()
end

function WindowNavigation:closeFocused()
  self.gate:next()
  self.orchestrator:closeFocused()
end

function WindowNavigation:focusOtherDisplay()
  self.gate:next()
  local current = self.orchestrator:activeScreen()
  local screens = self.allScreens()
  if #screens < 2 or not current then return end
  table.sort(screens, function(first, second)
    local firstFrame, secondFrame = first:frame(), second:frame()
    if firstFrame.x ~= secondFrame.x then return firstFrame.x < secondFrame.x end
    return firstFrame.y < secondFrame.y
  end)
  local currentID = WindowRepository.screenIdentifier(current)
  local currentIndex = 1
  for index, screen in ipairs(screens) do
    if WindowRepository.screenIdentifier(screen) == currentID then currentIndex = index; break end
  end
  local targetScreen = screens[currentIndex % #screens + 1]
  local targetID = WindowRepository.screenIdentifier(targetScreen)
  self:_records(function(records)
    local candidates = {}
    for _, record in ipairs(self.repository:orderedByHistory(records)) do
      if record.screenID == targetID and not record.minimized then
        candidates[#candidates + 1] = record
      end
    end
    local target = candidates[1]
    if target and target.window then target.window:focus() end
  end)
end

WindowNavigation.windowChoice = windowChoice

return WindowNavigation
