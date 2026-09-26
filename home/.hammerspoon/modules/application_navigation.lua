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

local function targetScreen(kind, currentScreen)
  if kind == "current" then
    return currentScreen or hs.screen.mainScreen(), false
  end

  local primary = hs.screen.primaryScreen()
  if kind ~= "secondary" then
    return primary, false
  end

  local secondary = secondaryScreen(primary)
  return secondary or primary, secondary == nil
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

function ApplicationNavigation:showWindow(window, request)
  local screen, usedFallback = targetScreen(request.screenKind, request.screen)

  if usedFallback then
    hs.alert.show("Secondary display unavailable; using primary", 1.5)
  end
  request.screen = screen
  self.navigation:activate(window, request)
end

function ApplicationNavigation:showOrChoose(windows, request, chooseInstance)
  if chooseInstance then
    self.chooser:show(windows, function(window)
      self:showWindow(window, request)
    end)
    return
  end
  self:showWindow(windows[1], request)
end

function ApplicationNavigation:requestNewWindow(application, running)
  if application.newWindowShortcut then
    hs.eventtap.keyStroke(
      application.newWindowShortcut.modifiers,
      application.newWindowShortcut.key,
      0,
      running
    )
    return
  end

  if application.bundleID then
    hs.task.new("/usr/bin/open", nil, {"-b", application.bundleID}):start()
  end
end

function ApplicationNavigation:waitForWindow(application, request, chooseInstance, serial)
  local deadline = hs.timer.secondsSinceEpoch() + self.timeout
  local running = runningApplication(application)
  local reopenAt = hs.timer.secondsSinceEpoch() + 0.25
  local reopenRequested = false

  local function poll()
    if serial ~= self.requestSerial then
      return
    end

    local windows = self:matchingWindows(application)
    if #windows > 0 then
      self:showOrChoose(windows, request, chooseInstance)
      return
    end

    if running and not reopenRequested and hs.timer.secondsSinceEpoch() >= reopenAt then
      reopenRequested = true
      self:requestNewWindow(application, running)
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

  local launched = running ~= nil
  if running then
    running:activate(true)
  else
    if application.bundleID then
      launched = hs.application.launchOrFocusByBundleID(application.bundleID)
    end
    if not launched then
      launched = hs.application.launchOrFocus(application.name)
    end
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

function ApplicationNavigation:activate(application, request, chooseInstance)
  self.requestSerial = self.requestSerial + 1
  local serial = self.requestSerial
  local windows = self:matchingWindows(application)
  if #windows > 0 then
    self:showOrChoose(windows, request, chooseInstance)
    return
  end

  self:waitForWindow(application, request, chooseInstance, serial)
end

function ApplicationNavigation:chooseAny(request)
  self.requestSerial = self.requestSerial + 1
  self.chooser:show(self.navigation:allWindows(), function(window)
    self:showWindow(window, request)
  end)
end

return ApplicationNavigation
