local planner = require("modules.layout_planner")
local WindowRepository = require("modules.window_repository")

local LayoutOrchestrator = {}
LayoutOrchestrator.__index = LayoutOrchestrator

function LayoutOrchestrator.new(repository, gate, options, runtime)
  options = options or {}
  runtime = runtime or {}
  return setmetatable({
    repository = repository,
    gate = gate,
    gap = options.gap or 0,
    restoreDelay = options.restoreDelaySeconds or 0.08,
    layouts = {},
    listeners = {},
    after = runtime.after or function(delay, callback) hs.timer.doAfter(delay, callback) end,
    mainScreen = runtime.mainScreen or function() return hs.screen.mainScreen() end,
  }, LayoutOrchestrator)
end

function LayoutOrchestrator:subscribe(listener)
  self.listeners[#self.listeners + 1] = listener
  return function()
    for index, candidate in ipairs(self.listeners) do
      if candidate == listener then table.remove(self.listeners, index); return end
    end
  end
end

function LayoutOrchestrator:_notify()
  for _, listener in ipairs(self.listeners) do
    local ok, message = pcall(listener)
    if not ok and hs and hs.printf then hs.printf("Layout listener failed: %s", message) end
  end
end

function LayoutOrchestrator:layoutWindows()
  local result, seen = {}, {}
  for _, layout in pairs(self.layouts) do
    for _, windowID in ipairs(layout.ids) do
      if not seen[windowID] then
        local item = self.repository:recordForID(windowID)
        if item then
          seen[windowID] = true
          result[#result + 1] = item
        end
      end
    end
  end
  return result
end

function LayoutOrchestrator:_screenKey(screen)
  return WindowRepository.screenIdentifier(screen)
end

function LayoutOrchestrator:_window(windowID)
  local item = self.repository:recordForID(windowID)
  return item and item.window or nil
end

function LayoutOrchestrator:_layout(screen, create)
  if not screen then return nil end
  local key = self:_screenKey(screen)
  local layout = self.layouts[key]
  if not layout and create then
    layout = {screen = screen, ids = {}}
    self.layouts[key] = layout
  elseif layout then
    layout.screen = screen
  end
  return layout
end

function LayoutOrchestrator:_prune(layout)
  if not layout then return {} end
  local ids = {}
  for _, windowID in ipairs(layout.ids) do
    if self:_window(windowID) then ids[#ids + 1] = windowID end
  end
  layout.ids = ids
  return ids
end

function LayoutOrchestrator:_reflow(layout)
  local ids = self:_prune(layout)
  if #ids == 0 then return end
  local frames = planner.frames(layout.screen:frame(), #ids, self.gap)
  for index, windowID in ipairs(ids) do
    local window = self:_window(windowID)
    if window then window:setFrameWithWorkarounds(frames[index], 0) end
  end
end

function LayoutOrchestrator:_removeFromOtherLayouts(windowID, keepLayout)
  for _, layout in pairs(self.layouts) do
    if layout ~= keepLayout then
      local kept, changed = {}, false
      for _, existingID in ipairs(layout.ids) do
        if existingID == windowID then changed = true else kept[#kept + 1] = existingID end
      end
      if changed then
        layout.ids = kept
        self:_reflow(layout)
      end
    end
  end
end

function LayoutOrchestrator:_prepare(window, callback)
  local application = window:application()
  if application and application:isHidden() then application:unhide() end
  if window:isMinimized() then window:unminimize() end
  self.after(self.restoreDelay, callback)
end

function LayoutOrchestrator:activeScreen()
  local focused = self.repository.focusedWindow()
  return focused and focused:screen() or self.mainScreen()
end

function LayoutOrchestrator:activate(target, request, callback)
  callback = callback or function() end
  if not target or not target.window or not self.gate:isCurrent(request.generation) then return end
  local screen = request.screen or self:activeScreen() or target.screen
  if not screen then callback(false); return end
  self:_prepare(target.window, function()
    if not self.gate:isCurrent(request.generation)
        or not self.repository:isUsable(target.window) then return end
    local layout = self:_layout(screen, true)
    self:_removeFromOtherLayouts(target.id, layout)
    self:_prune(layout)
    if request.mode == "stack" then
      if request.anchorID and request.anchorID ~= target.id and self:_window(request.anchorID) then
        local containsAnchor = false
        for _, windowID in ipairs(layout.ids) do
          if windowID == request.anchorID then containsAnchor = true; break end
        end
        if not containsAnchor then layout.ids = {request.anchorID} end
      end
      local ids = {}
      for _, windowID in ipairs(layout.ids) do
        if windowID ~= target.id then ids[#ids + 1] = windowID end
      end
      ids[#ids + 1] = target.id
      layout.ids = ids
    else
      layout.ids = {target.id}
    end
    self:_reflow(layout)
    target.window:focus()
    layout.lastFocusedID = target.id
    self:_notify()
    callback(true)
  end)
end

function LayoutOrchestrator:focusNext()
  local screen = self:activeScreen()
  local layout = self:_layout(screen, false)
  local ids = self:_prune(layout)
  if #ids < 2 then return end
  local focused = self.repository.focusedWindow()
  local focusedID = focused and focused:id()
  local index = 0
  for candidateIndex, windowID in ipairs(ids) do
    if windowID == focusedID then index = candidateIndex; break end
  end
  local targetID = ids[index % #ids + 1]
  local target = self:_window(targetID)
  if target then
    target:focus()
    layout.lastFocusedID = targetID
    self:_notify()
  end
end

function LayoutOrchestrator:rotatePositions()
  local screen = self:activeScreen()
  local layout = self:_layout(screen, false)
  local ids = self:_prune(layout)
  if #ids < 2 then return end
  local focused = self.repository.focusedWindow()
  local focusedID = focused and focused:id()
  local focusedIndex = 1
  for index, windowID in ipairs(ids) do
    if windowID == focusedID then focusedIndex = index; break end
  end
  local firstID = table.remove(ids, 1)
  ids[#ids + 1] = firstID
  layout.ids = ids
  self:_reflow(layout)
  local target = self:_window(ids[focusedIndex])
  if target then target:focus(); layout.lastFocusedID = ids[focusedIndex] end
  self:_notify()
end

function LayoutOrchestrator:closeFocused()
  local focused = self.repository.focusedWindow()
  if not self.repository:isUsable(focused) then return end
  local windowID = focused:id()
  focused:close()
  for _, layout in pairs(self.layouts) do
    local kept = {}
    for _, existingID in ipairs(layout.ids) do
      if existingID ~= windowID then kept[#kept + 1] = existingID end
    end
    layout.ids = kept
  end
  self:_notify()
  self.after(self.restoreDelay, function()
    for _, layout in pairs(self.layouts) do self:_reflow(layout) end
    self:_notify()
  end)
end

function LayoutOrchestrator:resetFocused()
  local focused = self.repository:record(self.repository.focusedWindow())
  if not focused then return end
  local generation = self.gate:next()
  self:activate(focused, {
    generation = generation,
    mode = "single",
    screen = focused.screen or self:activeScreen(),
  })
end

return LayoutOrchestrator
