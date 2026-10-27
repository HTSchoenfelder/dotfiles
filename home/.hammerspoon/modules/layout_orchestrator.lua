local planner = require("modules.layout_planner")
local LayoutObserver = require("modules.layout_observer")
local WindowRepository = require("modules.window_repository")

local LayoutOrchestrator = {}
LayoutOrchestrator.__index = LayoutOrchestrator

local function copy(frame)
  return {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
end

local function sameFrame(a, b, tolerance)
  return a and b and math.abs(a.x - b.x) <= tolerance
    and math.abs(a.y - b.y) <= tolerance
    and math.abs(a.w - b.w) <= tolerance
    and math.abs(a.h - b.h) <= tolerance
end

function LayoutOrchestrator.new(repository, gate, options, runtime)
  options, runtime = options or {}, runtime or {}
  local self = setmetatable({
    repository = repository, gate = gate, layouts = {}, listeners = {},
    activeKey = nil, pendingBundles = {}, pendingCreated = {}, gap = options.gap or 0,
    frameTolerance = options.frameTolerance or 2,
    restoreDelay = options.restoreDelaySeconds or 0.08,
    after = runtime.after or function(delay, callback) hs.timer.doAfter(delay, callback) end,
    mainScreen = runtime.mainScreen or function() return hs.screen.mainScreen() end,
  }, LayoutOrchestrator)
  self.observer = LayoutObserver.new({
    onFocus = function() self:_validateFocus() end,
    onMove = function(window) self:_validateMove(window) end,
    onLifecycle = function(window) self:_validateLifecycle(window) end,
    onCreated = function(window) self:_created(window) end,
    onScreensChanged = function() self:clearAll() end,
  }, options, runtime)
  return self
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

function LayoutOrchestrator:_key(screen)
  return WindowRepository.screenIdentifier(screen)
end

function LayoutOrchestrator:_window(id)
  local record = id and self.repository:recordForID(id)
  return record and record.window
end

function LayoutOrchestrator:_layout(screen)
  if not screen then return end
  local key = self:_key(screen)
  local layout = self.layouts[key]
  if not layout then
    layout = {screen = screen, slots = {{windowID = nil}}, wanted = 1,
      focusedSlot = 1, ratio = 0.7, revision = 0}
    self.layouts[key] = layout
    local focused = self.repository.focusedWindow()
    if focused and focused:screen() and self:_key(focused:screen()) == key
        and self.repository:isUsable(focused) then
      layout.slots[1].windowID = tonumber(focused:id())
    end
    self:_reflow(layout)
  else
    layout.screen = screen
  end
  return layout, key
end

function LayoutOrchestrator:_slotForWindow(id)
  if not id then return end
  for key, layout in pairs(self.layouts) do
    for index = 1, layout.wanted do
      if layout.slots[index] and layout.slots[index].windowID == tonumber(id) then
        return layout, index, key
      end
    end
  end
end

function LayoutOrchestrator:activeScreen()
  local layout = self.activeKey and self.layouts[self.activeKey]
  if layout then return layout.screen end
  local focused = self.repository.focusedWindow()
  return focused and focused:screen() or self.mainScreen()
end

function LayoutOrchestrator:focusedWindowID()
  local focused = self.repository.focusedWindow()
  return focused and tonumber(focused:id()) or nil
end

function LayoutOrchestrator:layoutSnapshot()
  local result = {}
  for key, layout in pairs(self.layouts) do
    local slots = {}
    for index = 1, layout.wanted do
      local slot = layout.slots[index]
      if slot and slot.frame then
        slots[index] = {windowID = slot.windowID, frame = copy(slot.frame)}
      end
    end
    result[key] = {screen = layout.screen, slots = slots, wanted = layout.wanted,
      focusedSlot = layout.focusedSlot, active = key == self.activeKey}
  end
  return result
end

function LayoutOrchestrator:_focus(window)
  if not window then return end
  local focused = self.repository.focusedWindow()
  if not focused or focused:id() ~= window:id() then window:focus() end
end

function LayoutOrchestrator:_raise(window)
  if window then window:raise() end
end

function LayoutOrchestrator:_apply(slot)
  local window = slot and self:_window(slot.windowID)
  if not window or not slot.frame then return end
  local ok, frame = pcall(window.frame, window)
  if not ok or not sameFrame(frame, slot.frame, self.frameTolerance) then
    window:setFrameWithWorkarounds(slot.frame, 0)
  end
end

function LayoutOrchestrator:_reflow(layout)
  local left = layout.slots[1] and layout.slots[1].windowID
  local right = layout.slots[2] and layout.slots[2].windowID
  local frames = planner.frames(layout.screen:frame(), layout.wanted, self.gap, layout.ratio)
  if layout.wanted == 1 or (left and right) then
    for index = 1, layout.wanted do
      layout.slots[index].frame = copy(frames[index])
      self:_apply(layout.slots[index])
    end
  elseif left or right then
    local index = left and 1 or 2
    layout.slots[index].frame = copy(planner.frames(layout.screen:frame(), 1, self.gap)[1])
    layout.slots[3 - index].frame = nil
    self:_apply(layout.slots[index])
  else
    for index = 1, layout.wanted do layout.slots[index].frame = copy(frames[index]) end
  end
end

function LayoutOrchestrator:_prepare(window, callback)
  local application = window:application()
  local restored = false
  if application and application:isHidden() then application:unhide(); restored = true end
  if window:isMinimized() then window:unminimize(); restored = true end
  if restored then self.after(self.restoreDelay, callback) else callback() end
end

function LayoutOrchestrator:_available(exceptID)
  local result
  self.repository:listAll(function(records)
    for _, record in ipairs(self.repository:orderedByHistory(records)) do
      if record.id ~= exceptID and WindowRepository.isSlotCandidate(record)
          and not self:_slotForWindow(record.id) then
        result = record
        break
      end
    end
  end)
  return result
end

function LayoutOrchestrator:capture(mode, generation)
  local screen = self:activeScreen()
  local layout, key = self:_layout(screen)
  if not layout then return end
  if not self.activeKey then self.activeKey = key; self:_notify() end
  local focused = self.repository.focusedWindow()
  return {generation = generation, screen = screen, screenKey = key,
    index = mode == "other" and 3 - layout.focusedSlot or layout.focusedSlot,
    focusedSlot = layout.focusedSlot, revision = layout.revision,
    originalID = focused and tonumber(focused:id()), mode = mode or "focused"}
end

function LayoutOrchestrator:_current(request)
  local layout = request and self.layouts[request.screenKey]
  return layout and self.gate:isCurrent(request.generation)
    and self.activeKey == request.screenKey and layout.revision == request.revision
    and layout.focusedSlot == request.focusedSlot
end

function LayoutOrchestrator:excluded(request)
  local layout = request and self.layouts[request.screenKey]
  return request and request.mode == "other" and layout
    and layout.slots[layout.focusedSlot].windowID or nil
end

function LayoutOrchestrator:expectBundle(bundleID, enabled)
  self.pendingBundles[bundleID] = enabled and true or nil
end

function LayoutOrchestrator:_created(window)
  local id = window and tonumber(window:id())
  if not id or self:_slotForWindow(id) then return end
  local ok, title = pcall(window.title, window)
  if ok and not WindowRepository.isSlotCandidate({title = title}) then return end
  local layout = self.activeKey and self.layouts[self.activeKey]
  if not layout then return end
  local request = {generation = self.gate:current(), screen = layout.screen,
    screenKey = self.activeKey, index = layout.focusedSlot,
    focusedSlot = layout.focusedSlot, revision = layout.revision, mode = "focused"}
  for index = 1, layout.wanted do
    if not layout.slots[index].windowID then request.index = index; break end
  end
  if request.index ~= layout.focusedSlot then request.mode = "other" end
  local focused = self.repository.focusedWindow()
  request.originalID = focused and tonumber(focused:id())
  self.pendingCreated[id] = true
  self.after(self.restoreDelay, function()
    self.pendingCreated[id] = nil
    local record = self.repository:recordForID(id)
    if record and not self.pendingBundles[record.bundleID]
        and WindowRepository.isSlotCandidate(record) then
      self:activate(record, request)
    end
  end)
end

function LayoutOrchestrator:activate(target, request, callback)
  callback = callback or function() end
  if not WindowRepository.isSlotCandidate(target) or not target.window
      or not self:_current(request) then return end
  self:_prepare(target.window, function()
    if not self:_current(request) or not self.repository:isUsable(target.window) then return end
    local layout = self.layouts[request.screenKey]
    local index = request.index
    local source, sourceIndex = self:_slotForWindow(target.id)
    if source == layout and sourceIndex == index then
      self:_reflow(layout)
      if request.mode ~= "other" then self:_focus(target.window) end
      self:_notify()
      callback(true)
      return
    end
    if request.mode == "other" and source == layout
        and sourceIndex == layout.focusedSlot then return end
    local original = self:_window(request.originalID) or self.repository.focusedWindow()
    local old = layout.slots[index] and layout.slots[index].windowID
    layout.slots[index] = layout.slots[index] or {windowID = nil}
    layout.slots[index].windowID = target.id
    layout.wanted = math.max(layout.wanted, index)
    layout.revision = layout.revision + 1
    if source == layout then
      source.slots[sourceIndex].windowID = old
    elseif source then
      source.slots[sourceIndex].windowID = nil
      source.revision = source.revision + 1
    end
    if source and source ~= layout then self:_reflow(source) end
    self:_reflow(layout)
    if request.mode == "other" then
      self:_raise(target.window)
      if original and original ~= target.window then
        if original:screen() and self:_key(original:screen()) ~= request.screenKey then
          self.ignoreFocusID = tonumber(original:id())
        end
        self:_focus(original)
      end
    else
      layout.focusedSlot = index
      self:_focus(target.window)
    end
    self.activeKey = request.screenKey
    self:_notify()
    callback(true)
  end)
end

function LayoutOrchestrator:adopt(target, request, callback)
  self:activate(target, request, callback)
end

function LayoutOrchestrator:_refill(layout, index, closedID, focusReplacement)
  if layout.slots[index].windowID then return end
  local candidate = self:_available(closedID)
  if not candidate then
    if focusReplacement and layout.wanted == 2 then
      local peer = self:_window(layout.slots[3 - index].windowID)
      if peer then layout.focusedSlot = 3 - index; self:_focus(peer) end
    end
    self:_reflow(layout)
    self:_notify()
    return
  end
  local original = self.repository.focusedWindow()
  self:_prepare(candidate.window, function()
    if layout.slots[index].windowID or not self.repository:isUsable(candidate.window)
        or self:_slotForWindow(candidate.id) then return end
    layout.slots[index].windowID = candidate.id
    layout.revision = layout.revision + 1
    self:_reflow(layout)
    if focusReplacement then
      self:_focus(candidate.window)
    else
      self:_raise(candidate.window)
      if original and original ~= candidate.window then
        if original:screen() and self:_key(original:screen()) ~= self:_key(layout.screen) then
          self.ignoreFocusID = tonumber(original:id())
        end
        self:_focus(original)
      end
    end
    self:_notify()
  end)
end

function LayoutOrchestrator:_focusedCandidate(layout)
  local focused = self.repository.focusedWindow()
  if not focused or not self.repository:isUsable(focused)
      or self:_key(focused:screen()) ~= self:_key(layout.screen) then return end
  local id = tonumber(focused:id())
  local record = id and self.repository:recordForID(id)
  if WindowRepository.isSlotCandidate(record) then return id end
end

function LayoutOrchestrator:keepOnly()
  local layout, key = self:_layout(self:activeScreen())
  if not layout then return end
  local focusedID = self:_focusedCandidate(layout)
  local id = focusedID or layout.slots[layout.focusedSlot].windowID
  if not id then return end
  local source, sourceIndex, sourceKey = self:_slotForWindow(id)
  if source and sourceKey ~= key then
    source.slots[sourceIndex].windowID = nil
    source.revision = source.revision + 1
    self:_reflow(source)
  end
  layout.slots = {{windowID = id}}
  layout.wanted, layout.focusedSlot = 1, 1
  layout.revision = layout.revision + 1
  self.activeKey = key
  self:_reflow(layout)
  self:_notify()
end

function LayoutOrchestrator:enableTwo()
  local layout, key = self:_layout(self:activeScreen())
  if not layout then return end
  self.activeKey = key
  if layout.wanted ~= 2 then
    local focusedID = self:_focusedCandidate(layout)
    if focusedID and focusedID ~= layout.slots[layout.focusedSlot].windowID then
      local source, sourceIndex = self:_slotForWindow(focusedID)
      layout.slots[layout.focusedSlot].windowID = focusedID
      layout.revision = layout.revision + 1
      if source then
        source.slots[sourceIndex].windowID = nil
        source.revision = source.revision + 1
        if source ~= layout then self:_reflow(source) end
      end
    end
    layout.wanted = 2
    layout.slots[2] = layout.slots[2] or {windowID = nil}
    layout.revision = layout.revision + 1
  end
  if not layout.slots[layout.focusedSlot].windowID then
    self:_refill(layout, layout.focusedSlot, nil, true)
  end
  self:_refill(layout, 3 - layout.focusedSlot, nil, false)
end

function LayoutOrchestrator:toggleRatio()
  local layout, key = self:_layout(self:activeScreen())
  if not layout then return end
  self.activeKey = key
  layout.ratio = layout.ratio > 0.6 and 0.5 or 0.7
  self:_reflow(layout)
  self:_notify()
end

function LayoutOrchestrator:focusNext()
  local layout = self:_layout(self:activeScreen())
  if not layout or layout.wanted ~= 2 then return end
  local index = 3 - layout.focusedSlot
  local window = self:_window(layout.slots[index].windowID)
  if not window then return end
  layout.focusedSlot = index
  self:_focus(window)
  self:_notify()
end

function LayoutOrchestrator:rotatePositions()
  local layout = self:_layout(self:activeScreen())
  if not layout or layout.wanted ~= 2 or not layout.slots[1].windowID
      or not layout.slots[2].windowID then return end
  layout.slots[1].windowID, layout.slots[2].windowID =
    layout.slots[2].windowID, layout.slots[1].windowID
  layout.revision = layout.revision + 1
  self:_reflow(layout)
  self:_focus(self:_window(layout.slots[layout.focusedSlot].windowID))
  self:_notify()
end

function LayoutOrchestrator:switchScreen(screen)
  local layout, key = self:_layout(screen)
  if not layout then return end
  self.observer.focusGeneration = self.observer.focusGeneration + 1
  self.activeKey = key
  if not layout.slots[1].windowID and layout.wanted == 1 then
    self.repository:listAll(function(records)
      for _, record in ipairs(self.repository:orderedByHistory(records)) do
        if record.screenID == key and WindowRepository.isSlotCandidate(record)
            and not record.minimized and record.visible ~= false
            and not self:_slotForWindow(record.id) then
          layout.slots[1].windowID = record.id
          layout.revision = layout.revision + 1
          break
        end
      end
    end)
  end
  local window = self:_window(layout.slots[layout.focusedSlot].windowID)
  if not window and layout.wanted == 2 then
    window = self:_window(layout.slots[3 - layout.focusedSlot].windowID)
    if window then layout.focusedSlot = 3 - layout.focusedSlot end
  end
  self:_reflow(layout)
  self:_focus(window)
  self:_notify()
end

function LayoutOrchestrator:closeFocused()
  local focused = self.repository.focusedWindow()
  if not self.repository:isUsable(focused) then return end
  local id = tonumber(focused:id())
  local layout, index = self:_slotForWindow(id)
  local screen = focused:screen()
  if self.activeKey and screen and self.activeKey ~= self:_key(screen) then return end
  focused:close()
  if layout then self:_vacate(layout, index, id, true) end
end

function LayoutOrchestrator:_vacate(layout, index, id, focused)
  if layout.slots[index].windowID ~= id then return end
  layout.slots[index].windowID = nil
  layout.revision = layout.revision + 1
  self.after(self.restoreDelay, function()
    self:_refill(layout, index, id, focused and self.activeKey == self:_key(layout.screen))
  end)
end

function LayoutOrchestrator:_validateFocus()
  local focused = self.repository.focusedWindow()
  if not focused or not self.repository:isUsable(focused) then return end
  if not WindowRepository.isSlotCandidate(self.repository:recordForID(focused:id())) then return end
  if self.pendingCreated[tonumber(focused:id())] then return end
  local application = focused:application()
  local bundleID = application and application:bundleID()
  if bundleID and self.pendingBundles[bundleID] then return end
  if self.ignoreFocusID == tonumber(focused:id()) then
    self.ignoreFocusID = nil
    return
  end
  local screen = focused:screen()
  local key = self:_key(screen)
  if not key then return end
  self.activeKey = key
  local source, index = self:_slotForWindow(focused:id())
  if source and source == self.layouts[key] then source.focusedSlot = index end
  self:_notify()
end

function LayoutOrchestrator:_validateMove(window)
  local id = window and tonumber(window:id())
  local layout, index = self:_slotForWindow(id)
  if not layout then return end
  local slot = layout.slots[index]
  if not sameFrame(window:frame(), slot.frame, self.frameTolerance) then
    slot.windowID = nil
    layout.revision = layout.revision + 1
    self:_notify()
  end
end

function LayoutOrchestrator:_validateLifecycle(window)
  local id = window and tonumber(window:id())
  local layout, index = self:_slotForWindow(id)
  if not layout then return end
  local record = self.repository:recordForID(id)
  if not record or record.minimized or record.visible == false then
    self:_vacate(layout, index, id,
      self.activeKey == self:_key(layout.screen) and layout.focusedSlot == index)
  end
end

function LayoutOrchestrator:clearScreen(screen)
  local key = type(screen) == "string" and screen or self:_key(screen)
  if not key or not self.layouts[key] then return false end
  self.layouts[key] = nil
  if self.activeKey == key then self.activeKey = nil end
  self:_notify()
  return true
end

function LayoutOrchestrator:clearAll()
  self.layouts, self.activeKey = {}, nil
  self:_notify()
end

function LayoutOrchestrator:start() self.observer:start(); return self end
function LayoutOrchestrator:stop() self.observer:stop() end
function LayoutOrchestrator:resetFocused() self:keepOnly() end

return LayoutOrchestrator
