local CommaSelection = {}
CommaSelection.__index = CommaSelection

function CommaSelection.new(registry, navigation)
  local self = setmetatable({
    registry = registry,
    navigation = navigation,
    session = nil,
  }, CommaSelection)

  self.releaseTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    if not self.session then
      return false
    end

    local flags = event:getFlags()
    if not flags.alt and not flags.cmd and not flags.ctrl and not flags.shift then
      local session = self.session
      self.session = nil
      hs.timer.doAfter(0.12, function()
        local selectedWindow = hs.window.focusedWindow()
        if self.registry:isManagedWindow(selectedWindow) then
          self.navigation:activate(selectedWindow, {
            screen = session.screen,
            anchor = session.anchor,
            stack = session.stack,
          })
        end
        self.navigation:endMutationLater()
        session.switcher = nil
        session.windowFilter = nil
      end)
    end
    return false
  end)
  self.releaseTap:start()
  return self
end

function CommaSelection:createSession(options)
  local context = self.navigation:captureContext()
  self.navigation:beginMutation()
  local applicationName = nil
  if options.instancesOnly and context.anchor then
    local owner = context.anchor:application()
    applicationName = owner and owner:name() or nil
  end

  local windowFilter
  if applicationName then
    windowFilter = hs.window.filter.new({
      override = {
        currentSpace = true,
        fullscreen = false,
        allowRoles = "AXStandardWindow",
      },
      [applicationName] = {},
    })
  else
    windowFilter = hs.window.filter.new()
      :setDefaultFilter({})
      :setOverrideFilter({
        currentSpace = true,
        fullscreen = false,
        allowRoles = "AXStandardWindow",
      })
  end

  return {
    screen = context.screen,
    anchor = context.anchor,
    stack = options.stack == true,
    windowFilter = windowFilter,
    switcher = hs.window.switcher.new(windowFilter),
  }
end

function CommaSelection:cycle(direction, options)
  if not self.session then
    self.session = self:createSession(options)
  elseif options.stack then
    self.session.stack = true
  end

  if direction < 0 then
    self.session.switcher:previous()
  else
    self.session.switcher:next()
  end
end

return CommaSelection
