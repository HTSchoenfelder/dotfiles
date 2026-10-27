local WindowRepository = require("modules.window_repository")

local WindowNavigation = {}
WindowNavigation.__index = WindowNavigation

local function icon(record)
  if type(record.bundleID) == "string" and record.bundleID ~= ""
      and hs and hs.image and hs.image.imageFromAppBundle then
    return hs.image.imageFromAppBundle(record.bundleID)
  end
end

local function windowChoice(record)
  local title = record.title ~= "" and record.title ~= record.appName and record.title or nil
  return {
    text = record.appName,
    subText = title,
    image = icon(record),
    kind = "window",
    id = record.id,
    record = record,
  }
end

function WindowNavigation.new(options)
  options.allScreens = options.allScreens or function() return hs.screen.allScreens() end
  return setmetatable(options, WindowNavigation)
end

function WindowNavigation:_records(callback)
  self.repository:listAll(function(records)
    local eligible = {}
    for _, record in ipairs(records or {}) do
      if WindowRepository.isSlotCandidate(record) then eligible[#eligible + 1] = record end
    end
    callback(eligible)
  end)
end

function WindowNavigation:chooseAny(mode, instancesOnly)
  local generation = self.gate:next()
  local request = self.orchestrator:capture(mode, generation)
  if not request then return end
  self:_records(function(records)
    if not self.gate:isCurrent(generation) then return end
    local focused = instancesOnly and self.repository:focusedRecord(records) or nil
    local choices = {}
    for _, record in ipairs(self.repository:orderedByHistory(records)) do
      if not instancesOnly or (focused and record.bundleID == focused.bundleID) then
        choices[#choices + 1] = windowChoice(record)
      end
    end
    local excluded = self.orchestrator:excluded(request)
    local chooser = self.chooserFactory()
    if excluded then
      local filtered = {}
      for _, choice in ipairs(choices) do
        if choice.id ~= excluded then filtered[#filtered + 1] = choice end
      end
      choices = filtered
    end
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

function WindowNavigation:acceptComma(record, request)
  self.orchestrator:adopt(record, request)
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

function WindowNavigation:_otherScreen(current)
  local screens = self.allScreens()
  if #screens < 2 or not current then return nil end
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
  return screens[currentIndex % #screens + 1]
end

function WindowNavigation:makeFocusedSingle(screen)
  self.gate:next()
  self.orchestrator:keepOnly(screen)
end

function WindowNavigation:enableTwo(screen, ratio)
  self.gate:next()
  self.orchestrator:enableTwo(screen, ratio)
end

function WindowNavigation:cycleLayout(commaSelection)
  local kind = "layout"
  local session = commaSelection.session
  if session and session.kind == kind and self.gate:isCurrent(session.generation) then
    commaSelection:cycle(kind, 1, {})
    return
  end

  local screen = self.orchestrator:activeScreen()
  if not screen then return end
  local generation = self.gate:next()
  local items = {
    {id = "single", text = "One slot, full screen"},
    {id = "half", text = "Two slots, 50:50", ratio = 0.5},
    {id = "wide", text = "Two slots, 70:30", ratio = 0.7},
  }
  commaSelection:cycle(kind, 1, {
    currentID = items[#items].id,
    screen = screen,
    load = function(done) done(items) end,
    onSelect = function(item)
      if not self.gate:isCurrent(generation) then return end
      hs.timer.doAfter(0, function()
        if not self.gate:isCurrent(generation) then return end
        if item.id == "single" then self:makeFocusedSingle(screen)
        else self:enableTwo(screen, item.ratio) end
      end)
    end,
  })
  if commaSelection.session then commaSelection.session.generation = generation end
end

function WindowNavigation:toggleRatio()
  self.gate:next()
  self.orchestrator:toggleRatio()
end

function WindowNavigation:focusOtherDisplay()
  self.gate:next()
  local targetScreen = self:_otherScreen(self.orchestrator:activeScreen())
  if not targetScreen then return end
  self.orchestrator:switchScreen(targetScreen)
end

WindowNavigation.windowChoice = windowChoice

return WindowNavigation
