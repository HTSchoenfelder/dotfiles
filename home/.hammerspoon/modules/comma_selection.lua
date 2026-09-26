local CommaSelection = {}
CommaSelection.__index = CommaSelection

function CommaSelection.new(navigation)
  return setmetatable({navigation = navigation, session = nil}, CommaSelection)
end

function CommaSelection:finish()
  if not self.session then
    return
  end
  local session = self.session
  self.session = nil
  if session.releaseTap then
    session.releaseTap:stop()
  end
  hs.timer.doAfter(0.12, function()
    self.navigation:focus(hs.window.focusedWindow())
    session.switcher = nil
    session.windowFilter = nil
    session.releaseTap = nil
  end)
end

function CommaSelection:createSession(instancesOnly)
  local applicationName
  local focused = hs.window.focusedWindow()
  if instancesOnly and self.navigation:isUsableWindow(focused) then
    local owner = focused:application()
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

  local session = {
    windowFilter = windowFilter,
    switcher = hs.window.switcher.new(windowFilter),
  }
  session.releaseTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    if not flags.alt and not flags.cmd and not flags.ctrl and not flags.shift then
      self:finish()
    end
    return false
  end)
  session.releaseTap:start()
  return session
end

function CommaSelection:cycle(direction, instancesOnly)
  if not self.session then
    self.session = self:createSession(instancesOnly)
  end
  if direction < 0 then
    self.session.switcher:previous()
  else
    self.session.switcher:next()
  end
end

return CommaSelection
