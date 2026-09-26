local layout = require("modules.display_layout")

local ApplicationNavigation = {}
ApplicationNavigation.__index = ApplicationNavigation

local function screenIdentifier(screen)
  if not screen then
    return nil
  end
  return screen:getUUID() or tostring(screen:id())
end

local function sameScreen(first, second)
  return first and second and screenIdentifier(first) == screenIdentifier(second)
end

local function secondaryScreen(primary)
  for _, screen in ipairs(hs.screen.allScreens()) do
    if not sameScreen(screen, primary) then
      return screen
    end
  end
end

local function targetScreen(kind)
  local primary = hs.screen.primaryScreen()
  if kind ~= "secondary" then
    return primary, false
  end

  local secondary = secondaryScreen(primary)
  return secondary or primary, secondary == nil
end

local function isUsableWindow(window)
  return window and window:isStandard() and not window:isFullScreen()
end

local function runningApplication(application)
  if application.bundleID then
    return hs.application.get(application.bundleID)
  end
  return hs.application.get(application.name)
end

function ApplicationNavigation.new(options, chooser, navigation)
  return setmetatable({
    chooser = chooser,
    navigation = navigation,
    timeout = options.launchTimeoutSeconds or 15,
    pollInterval = options.launchPollIntervalSeconds or 0.1,
    restoreDelay = options.restoreDelaySeconds or 0.08,
    requestSerial = 0,
  }, ApplicationNavigation)
end

function ApplicationNavigation:matchingWindows(application)
  local running = runningApplication(application)
  if not running then
    return {}
  end

  local windows = {}
  local runningPID = running:pid()
  for _, window in ipairs(self.navigation:allWindows()) do
    local owner = window:application()
    if owner and owner:pid() == runningPID then
      windows[#windows + 1] = window
    end
  end
  return windows
end

function ApplicationNavigation:showWindow(window, placement)
  local screen, usedFallback = targetScreen(placement.screen)
  local frame = layout.frame(screen:frame(), placement.position)
  local application = window:application()

  if usedFallback then
    hs.alert.show("Secondary display unavailable; using primary", 1.5)
  end
  if application and application:isHidden() then
    application:unhide()
  end
  if window:isMinimized() then
    window:unminimize()
  end

  hs.timer.doAfter(self.restoreDelay, function()
    if not isUsableWindow(window) then
      return
    end
    window:setFrame(frame, 0)
    window:focus()
  end)
end

function ApplicationNavigation:showOrChoose(windows, placement, chooseInstance)
  if chooseInstance then
    self.chooser:show(windows, function(window)
      self:showWindow(window, placement)
    end)
    return
  end
  self:showWindow(windows[1], placement)
end

function ApplicationNavigation:waitForWindow(application, placement, chooseInstance, serial)
  local deadline = hs.timer.secondsSinceEpoch() + self.timeout

  local function poll()
    if serial ~= self.requestSerial then
      return
    end

    local windows = self:matchingWindows(application)
    if #windows > 0 then
      self:showOrChoose(windows, placement, chooseInstance)
      return
    end

    if hs.timer.secondsSinceEpoch() >= deadline then
      hs.notify.new({
        title = "Hammerspoon",
        informativeText = "No window opened for " .. application.name,
      }):send()
      return
    end
    hs.timer.doAfter(self.pollInterval, poll)
  end

  local launched = false
  if application.bundleID then
    launched = hs.application.launchOrFocusByBundleID(application.bundleID)
  end
  if not launched then
    launched = hs.application.launchOrFocus(application.name)
  end
  if launched then
    poll()
  else
    hs.notify.new({
      title = "Hammerspoon",
      informativeText = "Could not launch " .. application.name,
    }):send()
  end
end

function ApplicationNavigation:activate(application, placement, chooseInstance)
  self.requestSerial = self.requestSerial + 1
  local serial = self.requestSerial
  local windows = self:matchingWindows(application)
  if #windows > 0 then
    self:showOrChoose(windows, placement, chooseInstance)
    return
  end

  self:waitForWindow(application, placement, chooseInstance, serial)
end

function ApplicationNavigation:chooseAny()
  self.requestSerial = self.requestSerial + 1
  self.chooser:show(self.navigation:allWindows(), function(window)
    self.navigation:focus(window)
  end)
end

return ApplicationNavigation
