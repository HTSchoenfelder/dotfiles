local CommaSelection = {}
CommaSelection.__index = CommaSelection

local function windowLabel(window)
  local owner = window:application()
  local applicationName = owner and owner:name() or "Window"
  local title = window:title()
  if not title or title == "" then
    title = applicationName
  end
  return applicationName .. " — " .. title
end

function CommaSelection.new(navigation, options)
  return setmetatable({
    navigation = navigation,
    rows = options.rows or 7,
    session = nil,
  }, CommaSelection)
end

function CommaSelection:complete(choice)
  local session = self.session
  if not session then
    return
  end
  self.session = nil
  if session.releaseTap then
    session.releaseTap:stop()
  end

  local window = choice and session.windowsByID[choice.windowID] or nil
  if window then
    self.navigation:activate(window, session.request)
  end
end

function CommaSelection:createSession(instancesOnly, request)
  local focused = hs.window.focusedWindow()
  local application = instancesOnly and focused and focused:application() or nil
  local applicationPID = application and application:pid() or nil
  local windows = {}
  local windowsByID = {}
  local choices = {}
  local focusedIndex

  for _, window in ipairs(self.navigation:allWindows()) do
    local owner = window:application()
    if not applicationPID or owner and owner:pid() == applicationPID then
      windows[#windows + 1] = window
      local windowID = window:id()
      windowsByID[windowID] = window
      choices[#choices + 1] = {text = windowLabel(window), windowID = windowID}
      if focused and focused:id() == windowID then
        focusedIndex = #windows
      end
    end
  end

  if #windows == 0 then
    return nil
  end

  local chooser = hs.chooser.new(function(choice) self:complete(choice) end)
  chooser:rows(self.rows)
  chooser:searchSubText(false)
  chooser:placeholderText("")
  chooser:choices(choices)
  chooser:query("")

  local session = {
    chooser = chooser,
    count = #windows,
    index = focusedIndex or 0,
    request = request,
    windowsByID = windowsByID,
  }
  session.releaseTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    if not flags.alt and not flags.cmd and not flags.ctrl and not flags.shift then
      local active = self.session
      if active then
        active.chooser:select(active.index)
      end
    end
    return false
  end)
  session.releaseTap:start()
  self.session = session
  chooser:show()
  hs.timer.doAfter(0.01, function()
    if self.session == session then
      chooser:selectedRow(session.index)
    end
  end)
  return session
end

function CommaSelection:cycle(direction, instancesOnly, request)
  local session = self.session or self:createSession(instancesOnly, request)
  if not session then
    return
  end

  session.index = (session.index - 1 + direction) % session.count + 1
  session.chooser:selectedRow(session.index)
end

return CommaSelection
