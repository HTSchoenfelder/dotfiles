local LayoutObserver = {}
LayoutObserver.__index = LayoutObserver

function LayoutObserver.new(callbacks, options, runtime)
  options = options or {}
  runtime = runtime or {}
  return setmetatable({
    callbacks = callbacks,
    delay = options.validationDelaySeconds or 0.08,
    focusGeneration = 0,
    moveGenerations = {},
    after = runtime.after or function(delay, callback) hs.timer.doAfter(delay, callback) end,
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
  }, LayoutObserver)
end

function LayoutObserver:_scheduleFocus()
  self.focusGeneration = self.focusGeneration + 1
  local generation = self.focusGeneration
  self.after(self.delay, function()
    if generation == self.focusGeneration then self.callbacks.onFocus() end
  end)
end

function LayoutObserver:_scheduleMove(window)
  local windowID = tonumber(window and window:id())
  if not windowID then return end
  self.moveGenerations[windowID] = (self.moveGenerations[windowID] or 0) + 1
  local generation = self.moveGenerations[windowID]
  self.after(self.delay, function()
    if generation ~= self.moveGenerations[windowID] then return end
    self.moveGenerations[windowID] = nil
    self.callbacks.onMove(window)
  end)
end

function LayoutObserver:_scheduleLifecycle(window)
  if not tonumber(window and window:id()) then return end
  self.after(self.delay, function() self.callbacks.onLifecycle(window) end)
end

function LayoutObserver:start()
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
      self:_scheduleFocus()
    elseif event == self.events.moved then
      self:_scheduleMove(window)
    else
      self:_scheduleLifecycle(window)
    end
  end)
  self.screenWatcher = self.screenWatcherNew(self.callbacks.onScreensChanged):start()
  return self
end

function LayoutObserver:stop()
  if self.filter then self.filter:unsubscribeAll(); self.filter = nil end
  if self.screenWatcher then self.screenWatcher:stop(); self.screenWatcher = nil end
end

return LayoutObserver
