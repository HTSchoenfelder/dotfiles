local planner = require("modules.layout_planner")
local WindowRepository = require("modules.window_repository")

local LayoutOrchestrator = {}
LayoutOrchestrator.__index = LayoutOrchestrator

local function copyFrame(frame)
  return {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
end

local function framesMatch(first, second, tolerance)
  if not first or not second then return false end
  return math.abs(first.x - second.x) <= tolerance
    and math.abs(first.y - second.y) <= tolerance
    and math.abs(first.w - second.w) <= tolerance
    and math.abs(first.h - second.h) <= tolerance
end

function LayoutOrchestrator.new(repository, gate, options, runtime)
  options = options or {}
  runtime = runtime or {}
  return setmetatable({
    repository = repository,
    gate = gate,
    gap = options.gap or 0,
    restoreDelay = options.restoreDelaySeconds or 0.08,
    validationDelay = options.validationDelaySeconds or 0.08,
    frameTolerance = options.frameTolerance or 2,
    layouts = {},
    listeners = {},
    focusValidation = 0,
    moveValidations = {},
    after = runtime.after or function(delay, callback) hs.timer.doAfter(delay, callback) end,
    mainScreen = runtime.mainScreen or function() return hs.screen.mainScreen() end,
    filterNew = runtime.filterNew or function()
      return hs.window.filter.new()
        :rejectApp("Hammerspoon")
        :rejectApp("Control Center")
        :rejectApp("Notification Center")
        :rejectApp("Spotlight")
    end,
    events = runtime.events or {
      destroyed = hs.window.filter.windowDestroyed,
      focused = hs.window.filter.windowFocused,
      moved = hs.window.filter.windowMoved,
      notInCurrentSpace = hs.window.filter.windowNotInCurrentSpace,
      notVisible = hs.window.filter.windowNotVisible,
    },
    screenWatcherNew = runtime.screenWatcherNew or function(callback)
      return hs.screen.watcher.new(callback)
    end,
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
    layout = {screen = screen, slots = {}, focusedSlot = 1}
    self.layouts[key] = layout
  elseif layout then
    layout.screen = screen
  end
  return layout, key
end

function LayoutOrchestrator:_slotForWindow(windowID)
  for screenKey, layout in pairs(self.layouts) do
    for index, slot in ipairs(layout.slots) do
      if slot.windowID == windowID then return layout, index, screenKey end
    end
  end
end

function LayoutOrchestrator:_prune(layout)
  if not layout then return {} end
  local slots = {}
  for _, slot in ipairs(layout.slots) do
    if self:_window(slot.windowID) then slots[#slots + 1] = slot end
  end
  layout.slots = slots
  layout.focusedSlot = math.min(layout.focusedSlot or 1, math.max(1, #slots))
  return slots
end

function LayoutOrchestrator:_applySlot(slot)
  local window = self:_window(slot.windowID)
  if window and slot.frame then window:setFrameWithWorkarounds(slot.frame, 0) end
end

function LayoutOrchestrator:_reflow(layout)
  local slots = self:_prune(layout)
  if #slots == 0 then return end
  local frames = planner.frames(layout.screen:frame(), #slots, self.gap)
  for index, slot in ipairs(slots) do
    slot.frame = copyFrame(frames[index])
    self:_applySlot(slot)
  end
end

function LayoutOrchestrator:_removeFromOtherLayouts(windowID, keepLayout)
  for screenKey, layout in pairs(self.layouts) do
    if layout ~= keepLayout then
      local kept, changed = {}, false
      for _, slot in ipairs(layout.slots) do
        if slot.windowID == windowID then changed = true else kept[#kept + 1] = slot end
      end
      if changed then
        layout.slots = kept
        if #kept == 0 then
          self.layouts[screenKey] = nil
        else
          layout.focusedSlot = math.min(layout.focusedSlot or 1, #kept)
          self:_reflow(layout)
        end
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

function LayoutOrchestrator:layoutSnapshot()
  local result = {}
  for screenKey, layout in pairs(self.layouts) do
    local slots = {}
    for index, slot in ipairs(layout.slots) do
      if slot.frame then
        slots[index] = {windowID = slot.windowID, frame = copyFrame(slot.frame)}
      end
    end
    if #slots > 0 then
      result[screenKey] = {
        screen = layout.screen,
        focusedSlot = layout.focusedSlot,
        slots = slots,
      }
    end
  end
  return result
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
        for _, slot in ipairs(layout.slots) do
          if slot.windowID == request.anchorID then containsAnchor = true; break end
        end
        if not containsAnchor then layout.slots = {{windowID = request.anchorID}} end
      end
      local slots = {}
      for _, slot in ipairs(layout.slots) do
        if slot.windowID ~= target.id then slots[#slots + 1] = slot end
      end
      slots[#slots + 1] = {windowID = target.id}
      layout.slots = slots
      layout.focusedSlot = #slots
    else
      layout.slots = {{windowID = target.id}}
      layout.focusedSlot = 1
    end
    self:_reflow(layout)
    target.window:focus()
    self:_notify()
    callback(true)
  end)
end

function LayoutOrchestrator:adopt(target, generation, callback)
  callback = callback or function() end
  if not target or not target.window or not self.gate:isCurrent(generation) then return end
  self:_prepare(target.window, function()
    if not self.gate:isCurrent(generation)
        or not self.repository:isUsable(target.window) then return end

    local existingLayout, existingIndex = self:_slotForWindow(target.id)
    if existingLayout then
      existingLayout.focusedSlot = existingIndex
      target.window:focus()
      self:_notify()
      callback(true)
      return
    end

    local screen = target.window:screen() or target.screen or self:activeScreen()
    if not screen then callback(false); return end
    local layout = self:_layout(screen, true)
    self:_removeFromOtherLayouts(target.id, layout)
    self:_prune(layout)
    if #layout.slots == 0 then
      layout.slots = {{windowID = target.id}}
      layout.focusedSlot = 1
      self:_reflow(layout)
    else
      local index = math.min(layout.focusedSlot or 1, #layout.slots)
      layout.slots[index] = {windowID = target.id, frame = copyFrame(layout.slots[index].frame)}
      layout.focusedSlot = index
      self:_applySlot(layout.slots[index])
    end
    target.window:focus()
    self:_notify()
    callback(true)
  end)
end

function LayoutOrchestrator:focusNext()
  local layout = self:_layout(self:activeScreen(), false)
  local slots = self:_prune(layout)
  if #slots < 2 then return end
  local focused = self.repository.focusedWindow()
  local focusedID = focused and focused:id()
  local index = layout.focusedSlot or 0
  for candidateIndex, slot in ipairs(slots) do
    if slot.windowID == focusedID then index = candidateIndex; break end
  end
  local targetIndex = index % #slots + 1
  local target = self:_window(slots[targetIndex].windowID)
  if target then
    layout.focusedSlot = targetIndex
    target:focus()
    self:_notify()
  end
end

function LayoutOrchestrator:rotatePositions()
  local layout = self:_layout(self:activeScreen(), false)
  local slots = self:_prune(layout)
  if #slots < 2 then return end
  local focused = self.repository.focusedWindow()
  local focusedID = focused and focused:id()
  local focusedIndex = layout.focusedSlot or 1
  for index, slot in ipairs(slots) do
    if slot.windowID == focusedID then focusedIndex = index; break end
  end
  local firstID = slots[1].windowID
  for index = 1, #slots - 1 do slots[index].windowID = slots[index + 1].windowID end
  slots[#slots].windowID = firstID
  for _, slot in ipairs(slots) do self:_applySlot(slot) end
  layout.focusedSlot = focusedIndex
  local target = self:_window(slots[focusedIndex].windowID)
  if target then target:focus() end
  self:_notify()
end

function LayoutOrchestrator:closeFocused()
  local focused = self.repository.focusedWindow()
  if not self.repository:isUsable(focused) then return end
  local windowID = focused:id()
  local layout, index, screenKey = self:_slotForWindow(windowID)
  if layout then
    table.remove(layout.slots, index)
    if #layout.slots == 0 then
      self.layouts[screenKey] = nil
    else
      layout.focusedSlot = math.min(index, #layout.slots)
      self:_reflow(layout)
    end
    self:_notify()
  end
  focused:close()
  if layout and #layout.slots > 0 then
    self.after(self.restoreDelay, function()
      local slot = layout.slots[layout.focusedSlot]
      local target = slot and self:_window(slot.windowID)
      if target then target:focus(); self:_notify() end
    end)
  end
end

function LayoutOrchestrator:clearScreen(screen)
  local screenKey = type(screen) == "string" and screen or self:_screenKey(screen)
  if not screenKey or not self.layouts[screenKey] then return false end
  self.layouts[screenKey] = nil
  self:_notify()
  return true
end

function LayoutOrchestrator:clearAll()
  if next(self.layouts) == nil then return end
  self.layouts = {}
  self:_notify()
end

function LayoutOrchestrator:_validateFocus()
  local focused = self.repository.focusedWindow()
  local record = self.repository:borderRecord(focused)
  if not record then return end
  local layout, index = self:_slotForWindow(record.id)
  if layout then
    if layout.focusedSlot ~= index then
      layout.focusedSlot = index
      self:_notify()
    end
    return
  end
  self:clearScreen(record.screen)
end

function LayoutOrchestrator:_scheduleFocusValidation()
  self.focusValidation = self.focusValidation + 1
  local generation = self.focusValidation
  self.after(self.validationDelay, function()
    if generation == self.focusValidation then self:_validateFocus() end
  end)
end

function LayoutOrchestrator:_scheduleMoveValidation(window)
  local windowID = tonumber(window and window:id())
  if not windowID then return end
  self.moveValidations[windowID] = (self.moveValidations[windowID] or 0) + 1
  local generation = self.moveValidations[windowID]
  self.after(self.validationDelay, function()
    if generation ~= self.moveValidations[windowID] then return end
    self.moveValidations[windowID] = nil
    local layout, index, screenKey = self:_slotForWindow(windowID)
    if not layout then return end
    local current = self.repository:borderRecord(window)
    local slot = layout.slots[index]
    if not current or not framesMatch(window:frame(), slot.frame, self.frameTolerance) then
      local destinationKey = current and current.screenID
      local changed = false
      if self.layouts[screenKey] then self.layouts[screenKey] = nil; changed = true end
      if destinationKey and destinationKey ~= screenKey and self.layouts[destinationKey] then
        self.layouts[destinationKey] = nil
        changed = true
      end
      if changed then self:_notify() end
    end
  end)
end

function LayoutOrchestrator:_scheduleLifecycleValidation(window)
  local windowID = tonumber(window and window:id())
  if not windowID then return end
  self.after(self.validationDelay, function()
    local _, _, screenKey = self:_slotForWindow(windowID)
    if not screenKey then return end
    local current = self.repository:borderRecord(window)
    if not current or current.minimized or not window:isVisible() then self:clearScreen(screenKey) end
  end)
end

function LayoutOrchestrator:start()
  if self.filter then return self end
  self.filter = self.filterNew()
  self.filter:subscribe({
    self.events.destroyed,
    self.events.focused,
    self.events.moved,
    self.events.notInCurrentSpace,
    self.events.notVisible,
  }, function(window, _, event)
    if event == self.events.focused then
      self:_scheduleFocusValidation()
    elseif event == self.events.moved then
      self:_scheduleMoveValidation(window)
    else
      self:_scheduleLifecycleValidation(window)
    end
  end)
  self.screenWatcher = self.screenWatcherNew(function() self:clearAll() end):start()
  return self
end

function LayoutOrchestrator:stop()
  if self.filter then self.filter:unsubscribeAll(); self.filter = nil end
  if self.screenWatcher then self.screenWatcher:stop(); self.screenWatcher = nil end
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
