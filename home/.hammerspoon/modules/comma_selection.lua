local CommaSelection = {}
CommaSelection.__index = CommaSelection

function CommaSelection.new(chooserFactory)
  return setmetatable({
    chooserFactory = chooserFactory,
    session = nil,
    serial = 0,
  }, CommaSelection)
end

function CommaSelection:cancel()
  local session = self.session
  self.session = nil
  self.serial = self.serial + 1
  if not session then return end
  if session.releaseTap then session.releaseTap:stop() end
  if session.chooser and session.chooser:isVisible() then session.chooser:hide() end
  if session.onCancel then session.onCancel() end
end

function CommaSelection:complete(choice)
  local session = self.session
  if not session then return end
  self.session = nil
  if session.releaseTap then session.releaseTap:stop() end
  if choice and session.onSelect then session.onSelect(choice.item) end
end

local function nextIndex(index, count, direction)
  return (index - 1 + direction) % count + 1
end

function CommaSelection:_show(session, items)
  if self.session ~= session or session.released then return end
  if not items or #items == 0 then self:cancel(); return end

  local choices = {}
  local focusedIndex = 0
  for index, item in ipairs(items) do
    choices[index] = {
      text = item.text,
      subText = item.subText,
      image = item.image,
      item = item,
    }
    if item.id == session.currentID then focusedIndex = index end
  end
  session.count = #items
  session.index = focusedIndex
  for _ = 1, math.abs(session.pendingDirection) do
    session.index = nextIndex(
      session.index,
      session.count,
      session.pendingDirection > 0 and 1 or -1
    )
  end

  session.chooser = self.chooserFactory()
  session.chooser:show(choices, function(choice) self:complete(choice) end, session.screen)
  hs.timer.doAfter(0.01, function()
    if self.session == session then session.chooser:selectedRow(session.index) end
  end)
end

function CommaSelection:_newSession(kind, direction, options)
  self:cancel()
  self.serial = self.serial + 1
  local session = {
    kind = kind,
    pendingDirection = direction,
    currentID = options.currentID,
    onSelect = options.onSelect,
    onCancel = options.onCancel,
    screen = options.screen,
    serial = self.serial,
  }
  session.releaseTap = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(event)
    local flags = event:getFlags()
    if not flags.alt and not flags.cmd and not flags.ctrl then
      local active = self.session
      if active == session then
        active.released = true
        if active.chooser and active.index then
          active.chooser:select(active.index)
        else
          self:cancel()
        end
      end
    end
    return false
  end)
  session.releaseTap:start()
  self.session = session
  options.load(function(items)
    if self.session == session and session.serial == self.serial then
      self:_show(session, items)
    end
  end)
  return session
end

function CommaSelection:cycle(kind, direction, options)
  local session = self.session
  if not session or session.kind ~= kind then
    self:_newSession(kind, direction, options)
    return
  end
  if session.count then
    session.index = nextIndex(session.index, session.count, direction)
    session.chooser:selectedRow(session.index)
  else
    session.pendingDirection = session.pendingDirection + direction
  end
end

CommaSelection.nextIndex = nextIndex

return CommaSelection
