local ApplicationNavigation = {}
ApplicationNavigation.__index = ApplicationNavigation

function ApplicationNavigation.new(registry, navigation, chooser, options)
  return setmetatable({
    registry = registry,
    navigation = navigation,
    chooser = chooser,
    timeout = options.launchTimeoutSeconds or 15,
    pollInterval = options.launchPollIntervalSeconds or 0.1,
    requestSerial = 0,
  }, ApplicationNavigation)
end

function ApplicationNavigation:showWindow(window, request)
  self.navigation:activate(window, {
    screen = request.screen,
    anchor = request.anchor,
    stack = request.stack,
  })
end

function ApplicationNavigation:choose(windows, request)
  self.chooser:show(windows, function(window)
    if window then
      self:showWindow(window, request)
    end
  end)
end

function ApplicationNavigation:waitForWindow(application, request)
  self.requestSerial = self.requestSerial + 1
  local serial = self.requestSerial
  local deadline = hs.timer.secondsSinceEpoch() + self.timeout
  self.navigation:beginMutation()

  local function poll()
    if serial ~= self.requestSerial then
      self.navigation:endMutationLater()
      return
    end

    local windows = self.registry:matchingWindows(application)
    if #windows > 0 then
      if request.chooseInstance then
        self:choose(windows, request)
      else
        self:showWindow(windows[1], request)
      end
      self.navigation:endMutationLater()
      return
    end

    if hs.timer.secondsSinceEpoch() >= deadline then
      hs.notify.new({
        title = "Hammerspoon",
        informativeText = "No window opened for " .. application.name,
      }):send()
      self.navigation:endMutationLater()
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
    self.navigation:endMutationLater()
  end
end

function ApplicationNavigation:activate(application, options)
  local context = self.navigation:captureContext()
  local request = {
    screen = context.screen,
    anchor = context.anchor,
    stack = options.stack == true,
    chooseInstance = options.chooseInstance == true,
  }
  local windows = self.registry:matchingWindows(application)

  if #windows == 0 then
    self:waitForWindow(application, request)
  elseif request.chooseInstance then
    self.requestSerial = self.requestSerial + 1
    self:choose(windows, request)
  else
    self.requestSerial = self.requestSerial + 1
    self:showWindow(windows[1], request)
  end
end

function ApplicationNavigation:chooseAny(options)
  self.requestSerial = self.requestSerial + 1
  local context = self.navigation:captureContext()
  self:choose(self.registry:allWindows(), {
    screen = context.screen,
    anchor = context.anchor,
    stack = options.stack == true,
  })
end

return ApplicationNavigation
