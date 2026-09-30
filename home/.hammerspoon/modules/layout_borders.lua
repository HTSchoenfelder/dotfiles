local LayoutBorders = {}
LayoutBorders.__index = LayoutBorders

local function call(object, method, fallback)
  if not object or type(object[method]) ~= "function" then return fallback end
  local ok, value = pcall(object[method], object)
  if ok then return value end
  return fallback
end

function LayoutBorders.new(orchestrator, options, runtime)
  options = options or {}
  runtime = runtime or {}
  return setmetatable({
    orchestrator = orchestrator,
    enabled = options.enabled ~= false,
    activeColor = options.activeColor or {hex = "#cba6f7"},
    inactiveColor = options.inactiveColor or {hex = "#585b70"},
    highlightFocused = options.highlightFocused ~= false,
    offset = options.offset or 2,
    radius = options.radius or 12,
    width = options.width or 3,
    canvases = {},
    canvasNew = runtime.canvasNew or function(frame) return hs.canvas.new(frame) end,
    focusedWindow = runtime.focusedWindow or function() return hs.window.focusedWindow() end,
    filterNew = runtime.filterNew or function()
      return hs.window.filter.new():rejectApp("Hammerspoon")
    end,
    events = runtime.events or {
      hs.window.filter.windowDestroyed,
      hs.window.filter.windowFocused,
      hs.window.filter.windowMoved,
      hs.window.filter.windowNotVisible,
      hs.window.filter.windowUnfocused,
      hs.window.filter.windowVisible,
    },
    canvasLevel = runtime.canvasLevel or hs.canvas.windowLevels.overlay,
    canvasBehavior = runtime.canvasBehavior or {
      "canJoinAllSpaces",
      "fullScreenAuxiliary",
      "ignoresCycle",
    },
  }, LayoutBorders)
end

function LayoutBorders:_delete(windowID)
  local canvas = self.canvases[windowID]
  if canvas then canvas:delete(); self.canvases[windowID] = nil end
end

function LayoutBorders:_draw(record, focusedID)
  local window = record.window
  if record.minimized or call(window, "isVisible", true) == false then
    self:_delete(record.id)
    return
  end
  local frame = call(window, "frame")
  if not frame then self:_delete(record.id); return end

  local padding = self.offset + self.width / 2
  local canvasFrame = {
    x = frame.x - padding,
    y = frame.y - padding,
    w = frame.w + padding * 2,
    h = frame.h + padding * 2,
  }
  local canvas = self.canvases[record.id]
  if not canvas then
    canvas = self.canvasNew(canvasFrame)
    canvas:level(self.canvasLevel)
    canvas:behavior(self.canvasBehavior)
    canvas:clickActivating(false)
    self.canvases[record.id] = canvas
  else
    canvas:frame(canvasFrame)
  end

  local isFocused = self.highlightFocused and record.id == focusedID
  canvas:replaceElements({
    type = "rectangle",
    action = "stroke",
    frame = {
      x = self.width / 2,
      y = self.width / 2,
      w = frame.w + self.offset * 2,
      h = frame.h + self.offset * 2,
    },
    roundedRectRadii = {xRadius = self.radius, yRadius = self.radius},
    strokeColor = isFocused and self.activeColor or self.inactiveColor,
    strokeJoinStyle = "round",
    strokeWidth = self.width,
  })
  canvas:show()
end

function LayoutBorders:refresh()
  if not self.enabled then return end
  local focused = self.focusedWindow()
  local focusedID = tonumber(call(focused, "id"))
  local present = {}
  for _, record in ipairs(self.orchestrator:layoutWindows()) do
    present[record.id] = true
    self:_draw(record, focusedID)
  end
  local stale = {}
  for windowID in pairs(self.canvases) do
    if not present[windowID] then stale[#stale + 1] = windowID end
  end
  for _, windowID in ipairs(stale) do self:_delete(windowID) end
end

function LayoutBorders:start()
  if not self.enabled then return self end
  self.unsubscribe = self.orchestrator:subscribe(function() self:refresh() end)
  self.filter = self.filterNew()
  self.filter:subscribe(self.events, function() self:refresh() end)
  self:refresh()
  return self
end

function LayoutBorders:stop()
  if self.unsubscribe then self.unsubscribe(); self.unsubscribe = nil end
  if self.filter then self.filter:unsubscribeAll(); self.filter = nil end
  local windowIDs = {}
  for windowID in pairs(self.canvases) do windowIDs[#windowIDs + 1] = windowID end
  for _, windowID in ipairs(windowIDs) do self:_delete(windowID) end
end

return LayoutBorders
