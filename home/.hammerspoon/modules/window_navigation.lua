local WindowNavigation = {}
WindowNavigation.__index = WindowNavigation

local function sortedScreens()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(first, second)
    local firstFrame = first:frame()
    local secondFrame = second:frame()
    if firstFrame.x == secondFrame.x then
      return firstFrame.y < secondFrame.y
    end
    return firstFrame.x < secondFrame.x
  end)
  return screens
end

function WindowNavigation.new(registry, layout, options)
  return setmetatable({
    registry = registry,
    layout = layout,
    restoreDelaySeconds = options.restoreDelaySeconds or 0.08,
    slots = {},
    mutationDepth = 0,
    reflowTimer = nil,
  }, WindowNavigation)
end

function WindowNavigation:activeScreen()
  local focused = hs.window.focusedWindow()
  if self.registry:isManagedWindow(focused) then
    return focused:screen()
  end
  return hs.screen.mainScreen()
end

function WindowNavigation:captureContext()
  local anchor = hs.window.focusedWindow()
  if not self.registry:isManagedWindow(anchor) then
    anchor = nil
  end
  return {screen = self:activeScreen(), anchor = anchor}
end

function WindowNavigation:beginMutation()
  self.mutationDepth = self.mutationDepth + 1
end

function WindowNavigation:endMutationLater()
  hs.timer.doAfter(0.3, function()
    self.mutationDepth = math.max(0, self.mutationDepth - 1)
  end)
end

function WindowNavigation:slotWindows(screen)
  local windows = {}
  local identifier = self.registry.screenIdentifier(screen)
  for _, windowID in ipairs(self.slots[identifier] or {}) do
    local window = self.registry:windowByID(windowID)
    if window and self.registry:isVisible(window) and self.registry:isOnScreen(window, screen) then
      windows[#windows + 1] = window
    end
  end

  for _, window in ipairs(self.registry:visibleOnScreen(screen)) do
    local alreadyIncluded = false
    for _, included in ipairs(windows) do
      if self.registry:windowID(included) == self.registry:windowID(window) then
        alreadyIncluded = true
        break
      end
    end
    if not alreadyIncluded then
      windows[#windows + 1] = window
    end
  end
  return windows
end

function WindowNavigation:applyLayout(screen, windows, focusWindow)
  local frames = self.layout.frames(screen:frame(), #windows)
  local identifiers = {}
  for index, window in ipairs(windows) do
    identifiers[index] = self.registry:windowID(window)
    window:setFrame(frames[index], 0)
  end
  self.slots[self.registry.screenIdentifier(screen)] = identifiers

  if focusWindow and self.registry:isManagedWindow(focusWindow) then
    focusWindow:focus()
    self.registry:recordFocus(focusWindow)
  end
end

function WindowNavigation:minimizeExcept(screen, keptWindows)
  local kept = {}
  for _, window in ipairs(keptWindows) do
    kept[self.registry:windowID(window)] = true
  end

  for _, window in ipairs(self.registry:visibleOnScreen(screen)) do
    if not kept[self.registry:windowID(window)] then
      window:minimize()
    end
  end
end

function WindowNavigation:activate(window, options)
  options = options or {}
  if not self.registry:isManagedWindow(window) then
    return
  end

  local targetScreen = options.screen or self:activeScreen()
  local sourceScreen = window:screen()
  local anchor = options.anchor
  local targetID = self.registry:windowID(window)
  self:beginMutation()

  local owner = window:application()
  if owner and owner:isHidden() then
    owner:unhide()
  end
  if window:isMinimized() then
    window:unminimize()
  end

  hs.timer.doAfter(self.restoreDelaySeconds, function()
    if not self.registry:isManagedWindow(window) then
      self:endMutationLater()
      return
    end

    window:moveToScreen(targetScreen, false, true, 0)
    local kept = {}
    if options.stack then
      if not self.registry:isManagedWindow(anchor)
          or not self.registry:isVisible(anchor)
          or not self.registry:isOnScreen(anchor, targetScreen)
          or self.registry:windowID(anchor) == targetID then
        anchor = nil
        for _, candidate in ipairs(self:slotWindows(targetScreen)) do
          if self.registry:windowID(candidate) ~= targetID then
            anchor = candidate
            break
          end
        end
      end
      if anchor then
        kept[#kept + 1] = anchor
      end
    end
    kept[#kept + 1] = window

    self:minimizeExcept(targetScreen, kept)
    self:applyLayout(targetScreen, kept, window)

    if sourceScreen and self.registry.screenIdentifier(sourceScreen)
        ~= self.registry.screenIdentifier(targetScreen) then
      self:reflow(sourceScreen)
    end
    self:endMutationLater()
  end)
end

function WindowNavigation:reflow(screen)
  if not screen then
    return
  end

  local windows = self:slotWindows(screen)
  if #windows == 0 then
    self.slots[self.registry.screenIdentifier(screen)] = {}
    return
  end

  if #windows > 2 then
    local focused = hs.window.focusedWindow()
    local kept = {}
    if self.registry:isVisible(focused) and self.registry:isOnScreen(focused, screen) then
      kept[#kept + 1] = focused
    end
    for _, window in ipairs(windows) do
      if #kept == 2 then
        break
      end
      if not kept[1] or self.registry:windowID(kept[1]) ~= self.registry:windowID(window) then
        kept[#kept + 1] = window
      end
    end
    self:minimizeExcept(screen, kept)
    windows = kept
  end

  self:applyLayout(screen, windows, nil)
end

function WindowNavigation:focusNext()
  local screen = self:activeScreen()
  local windows = self:slotWindows(screen)
  if #windows < 2 then
    return
  end

  local focusedID = self.registry:windowID(hs.window.focusedWindow())
  local nextWindow = windows[1]
  for index, window in ipairs(windows) do
    if self.registry:windowID(window) == focusedID then
      nextWindow = windows[index % #windows + 1]
      break
    end
  end
  nextWindow:focus()
end

function WindowNavigation:swapPositions()
  local focused = hs.window.focusedWindow()
  local screen = self:activeScreen()
  local windows = self:slotWindows(screen)
  if #windows ~= 2 then
    return
  end

  self:beginMutation()
  self:applyLayout(screen, {windows[2], windows[1]}, focused)
  self:endMutationLater()
end

function WindowNavigation:focusOtherDisplay()
  local screens = sortedScreens()
  if #screens < 2 then
    return
  end

  local currentIdentifier = self.registry.screenIdentifier(self:activeScreen())
  local currentIndex = 1
  for index, screen in ipairs(screens) do
    if self.registry.screenIdentifier(screen) == currentIdentifier then
      currentIndex = index
      break
    end
  end

  local targetScreen = screens[currentIndex % #screens + 1]
  local target = self.registry:lastFocusedOnScreen(targetScreen)
  if target then
    target:focus()
  end
end

function WindowNavigation:scheduleReflow(delay)
  if self.reflowTimer then
    self.reflowTimer:stop()
  end
  self.reflowTimer = hs.timer.doAfter(delay or 0.12, function()
    self.reflowTimer = nil
    if self.mutationDepth > 0 then
      return
    end
    for _, screen in ipairs(hs.screen.allScreens()) do
      self:reflow(screen)
    end
  end)
end

function WindowNavigation:start()
  self.registry:start(function()
    if self.mutationDepth > 0 then
      return
    end
    self:scheduleReflow()
  end)

  self.screenWatcher = hs.screen.watcher.new(function()
    self:scheduleReflow(0.5)
  end)
  self.screenWatcher:start()
  self:scheduleReflow(0.5)
end

return WindowNavigation
