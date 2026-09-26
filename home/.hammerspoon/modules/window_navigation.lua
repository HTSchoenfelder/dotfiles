local WindowNavigation = {}
WindowNavigation.__index = WindowNavigation

local function screenIdentifier(screen)
  if not screen then
    return nil
  end
  return screen:getUUID() or tostring(screen:id())
end

local function sameScreen(first, second)
  return first and second and screenIdentifier(first) == screenIdentifier(second)
end

local function isUsableWindow(window)
  return window and window:id() and window:isStandard() and not window:isFullScreen()
end

local function appendUnique(windows, seen, window)
  if not isUsableWindow(window) then
    return
  end
  local windowID = window:id()
  if not seen[windowID] then
    seen[windowID] = true
    windows[#windows + 1] = window
  end
end

function WindowNavigation.new(options)
  return setmetatable({
    restoreDelay = options.restoreDelaySeconds or 0.08,
  }, WindowNavigation)
end

function WindowNavigation:isUsableWindow(window)
  return isUsableWindow(window)
end

function WindowNavigation:activeScreen()
  local focused = hs.window.focusedWindow()
  if isUsableWindow(focused) then
    return focused:screen()
  end
  return hs.screen.mainScreen()
end

function WindowNavigation:orderedWindows(screen, application)
  local windows = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    local owner = window:application()
    if isUsableWindow(window)
        and (not screen or sameScreen(window:screen(), screen))
        and (not application or owner and owner:pid() == application:pid()) then
      windows[#windows + 1] = window
    end
  end
  return windows
end

function WindowNavigation:allWindows()
  local windows = {}
  local seen = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    appendUnique(windows, seen, window)
  end
  for _, window in ipairs(hs.window.allWindows()) do
    appendUnique(windows, seen, window)
  end
  return windows
end

function WindowNavigation:focus(window)
  if not isUsableWindow(window) then
    return
  end
  local application = window:application()
  if application and application:isHidden() then
    application:unhide()
  end
  if window:isMinimized() then
    window:unminimize()
  end
  hs.timer.doAfter(self.restoreDelay, function()
    if isUsableWindow(window) then
      window:focus()
    end
  end)
end

function WindowNavigation:focusNext()
  local focused = hs.window.focusedWindow()
  local windows = self:orderedWindows(self:activeScreen())
  if #windows < 2 then
    return
  end

  local nextWindow = windows[1]
  for index, window in ipairs(windows) do
    if window:id() == (focused and focused:id()) then
      nextWindow = windows[index % #windows + 1]
      break
    end
  end
  self:focus(nextWindow)
end

function WindowNavigation:swapPositions()
  local focused = hs.window.focusedWindow()
  if not isUsableWindow(focused) then
    return
  end

  local other
  for _, window in ipairs(self:orderedWindows(focused:screen())) do
    if window:id() ~= focused:id() then
      other = window
      break
    end
  end
  if not other then
    return
  end

  local focusedFrame = focused:frame()
  local otherFrame = other:frame()
  focused:setFrame(otherFrame, 0)
  other:setFrame(focusedFrame, 0)
  focused:focus()
end

function WindowNavigation:focusOtherDisplay()
  local currentScreen = self:activeScreen()
  local targetScreen
  for _, screen in ipairs(hs.screen.allScreens()) do
    if not sameScreen(screen, currentScreen) then
      targetScreen = screen
      break
    end
  end
  if not targetScreen then
    return
  end

  local windows = self:orderedWindows(targetScreen)
  if windows[1] then
    self:focus(windows[1])
  end
end

function WindowNavigation:closeFocused()
  local window = hs.window.focusedWindow()
  if isUsableWindow(window) then
    window:close()
  end
end

WindowNavigation.screenIdentifier = screenIdentifier

return WindowNavigation
