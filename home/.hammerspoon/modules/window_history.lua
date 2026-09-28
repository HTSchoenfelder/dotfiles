local WindowHistory = {}
WindowHistory.__index = WindowHistory

function WindowHistory.new()
  return setmetatable({serial = 0, focusedAt = {}, firstSeen = {}, filter = nil}, WindowHistory)
end

function WindowHistory:remember(windowID)
  windowID = tonumber(windowID)
  if not windowID then return end
  self.serial = self.serial + 1
  self.focusedAt[windowID] = self.serial
  self.firstSeen[windowID] = self.firstSeen[windowID] or self.serial
end

function WindowHistory:seed(windowIDs)
  for index = #windowIDs, 1, -1 do
    self:remember(windowIDs[index])
  end
end

function WindowHistory:sort(records)
  local ordered = {}
  for index, record in ipairs(records) do
    record._stableIndex = record._stableIndex or index
    ordered[index] = record
    self.firstSeen[record.id] = self.firstSeen[record.id] or (self.serial + index)
  end
  table.sort(ordered, function(first, second)
    local firstFocus = self.focusedAt[first.id] or -1
    local secondFocus = self.focusedAt[second.id] or -1
    if firstFocus ~= secondFocus then return firstFocus > secondFocus end
    local firstSeen = self.firstSeen[first.id] or math.huge
    local secondSeen = self.firstSeen[second.id] or math.huge
    if firstSeen ~= secondSeen then return firstSeen < secondSeen end
    return first.id < second.id
  end)
  return ordered
end

function WindowHistory:start()
  local ids = {}
  for _, window in ipairs(hs.window.orderedWindows()) do
    if window:id() then ids[#ids + 1] = window:id() end
  end
  self:seed(ids)
  self.filter = hs.window.filter.new()
  self.filter:subscribe(hs.window.filter.windowFocused, function(window)
    self:remember(window:id())
  end)
end

return WindowHistory
