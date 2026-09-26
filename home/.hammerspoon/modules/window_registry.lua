local Registry = {}
Registry.__index = Registry

local function safeValue(callback)
  local ok, value = pcall(callback)
  if ok then
    return value
  end
end

local function screenIdentifier(screen)
  if not screen then
    return nil
  end
  return screen:getUUID() or tostring(screen:id())
end

function Registry.new()
  return setmetatable({
    focusOrder = {},
    lastFocusedByScreen = {},
  }, Registry)
end

function Registry:windowID(window)
  return window and safeValue(function() return window:id() end) or nil
end

function Registry:isManagedWindow(window)
  if not self:windowID(window) then
    return false
  end

  return safeValue(function()
    return window:isStandard() and not window:isFullScreen()
  end) == true
end

function Registry:bundleID(window)
  return safeValue(function()
    local application = window:application()
    return application and application:bundleID() or nil
  end)
end

function Registry:matchesApplication(window, application)
  if not self:isManagedWindow(window) then
    return false
  end

  local bundleID = self:bundleID(window)
  if bundleID and application.bundleID then
    return bundleID == application.bundleID
  end

  return safeValue(function()
    local owner = window:application()
    return owner and owner:name() == application.name
  end) == true
end

function Registry:recordFocus(window)
  if not self:isManagedWindow(window) then
    return
  end

  local windowID = self:windowID(window)
  for index = #self.focusOrder, 1, -1 do
    if self.focusOrder[index] == windowID then
      table.remove(self.focusOrder, index)
    end
  end
  table.insert(self.focusOrder, 1, windowID)

  local screen = safeValue(function() return window:screen() end)
  local identifier = screenIdentifier(screen)
  if identifier then
    self.lastFocusedByScreen[identifier] = windowID
  end
end

function Registry:remove(window)
  local windowID = self:windowID(window)
  if not windowID then
    return
  end

  for index = #self.focusOrder, 1, -1 do
    if self.focusOrder[index] == windowID then
      table.remove(self.focusOrder, index)
    end
  end
end

function Registry:allWindows()
  local windows = {}
  for _, window in ipairs(hs.window.allWindows()) do
    if self:isManagedWindow(window) then
      windows[#windows + 1] = window
    end
  end

  local rank = {}
  for index, windowID in ipairs(self.focusOrder) do
    rank[windowID] = index
  end
  table.sort(windows, function(first, second)
    local firstID = self:windowID(first) or math.huge
    local secondID = self:windowID(second) or math.huge
    local firstRank = rank[firstID] or math.huge
    local secondRank = rank[secondID] or math.huge
    if firstRank == secondRank then
      return firstID < secondID
    end
    return firstRank < secondRank
  end)
  return windows
end

function Registry:windowByID(windowID)
  for _, window in ipairs(self:allWindows()) do
    if self:windowID(window) == windowID then
      return window
    end
  end
end

function Registry:isVisible(window)
  return self:isManagedWindow(window) and safeValue(function()
    return window:isVisible() and not window:isMinimized()
  end) == true
end

function Registry:isOnScreen(window, screen)
  local windowScreen = safeValue(function() return window:screen() end)
  return screenIdentifier(windowScreen) == screenIdentifier(screen)
end

function Registry:visibleOnScreen(screen)
  local windows = {}
  for _, window in ipairs(self:allWindows()) do
    if self:isVisible(window) and self:isOnScreen(window, screen) then
      windows[#windows + 1] = window
    end
  end
  return windows
end

function Registry:matchingWindows(application)
  local windows = {}
  for _, window in ipairs(self:allWindows()) do
    if self:matchesApplication(window, application) then
      windows[#windows + 1] = window
    end
  end
  return windows
end

function Registry:lastFocusedOnScreen(screen)
  local windowID = self.lastFocusedByScreen[screenIdentifier(screen)]
  local window = windowID and self:windowByID(windowID) or nil
  if window and self:isVisible(window) and self:isOnScreen(window, screen) then
    return window
  end

  return self:visibleOnScreen(screen)[1]
end

function Registry:start(callback)
  local ordered = hs.window.orderedWindows()
  for index = #ordered, 1, -1 do
    self:recordFocus(ordered[index])
  end

  self.windowFilter = hs.window.filter.new()
    :setCurrentSpace(true)
    :setDefaultFilter({})

  self.windowFilter:subscribe(hs.window.filter.windowFocused, function(window)
    self:recordFocus(window)
    callback("focused", window)
  end)
  self.windowFilter:subscribe(hs.window.filter.windowCreated, function(window)
    callback("created", window)
  end)
  self.windowFilter:subscribe(hs.window.filter.windowDestroyed, function(window)
    self:remove(window)
    callback("destroyed", window)
  end)

  for eventName, event in pairs({
    minimized = hs.window.filter.windowMinimized,
    unminimized = hs.window.filter.windowUnminimized,
    hidden = hs.window.filter.windowHidden,
    unhidden = hs.window.filter.windowUnhidden,
  }) do
    self.windowFilter:subscribe(event, function(window)
      callback(eventName, window)
    end)
  end
end

Registry.screenIdentifier = screenIdentifier

return Registry
