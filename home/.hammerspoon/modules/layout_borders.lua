local LayoutBorders = {}
LayoutBorders.__index = LayoutBorders

local function call(object, method, fallback)
  if not object or type(object[method]) ~= "function" then return fallback end
  local ok, value = pcall(object[method], object)
  if ok then return value end
  return fallback
end

local function framesMatch(first, second)
  return first and second
    and first.x == second.x
    and first.y == second.y
    and first.w == second.w
    and first.h == second.h
end

function LayoutBorders.new(orchestrator, options, runtime)
  options = options or {}
  runtime = runtime or {}
  return setmetatable({
    orchestrator = orchestrator,
    enabled = options.enabled ~= false,
    focusColor = options.focusColor or {hex = "#a6e3a1"},
    layoutColor = options.layoutColor or {hex = "#f5c2e7"},
    offset = options.offset or 2,
    radius = options.radius or 12,
    width = options.width or 4.5,
    canvases = {},
    canvasNew = runtime.canvasNew or function(frame) return hs.canvas.new(frame) end,
    focusedWindow = runtime.focusedWindow or function() return hs.window.focusedWindow() end,
    canvasLevel = runtime.canvasLevel or hs.canvas.windowLevels.overlay,
    canvasBehavior = runtime.canvasBehavior or {
      "canJoinAllSpaces",
      "fullScreenAuxiliary",
      "ignoresCycle",
    },
  }, LayoutBorders)
end

function LayoutBorders:_delete(key)
  local entry = self.canvases[key]
  if entry then entry.canvas:delete(); self.canvases[key] = nil end
end

function LayoutBorders:_draw(key, frame, color, colorName)
  local padding = self.offset + self.width / 2
  local canvasFrame = {
    x = frame.x - padding,
    y = frame.y - padding,
    w = frame.w + padding * 2,
    h = frame.h + padding * 2,
  }
  local entry = self.canvases[key]
  if entry and framesMatch(entry.frame, frame) and entry.colorName == colorName then return end

  if not entry then
    local canvas = self.canvasNew(canvasFrame)
    canvas:level(self.canvasLevel)
    canvas:behavior(self.canvasBehavior)
    canvas:clickActivating(false)
    entry = {canvas = canvas}
    self.canvases[key] = entry
  elseif not framesMatch(entry.frame, frame) then
    entry.canvas:frame(canvasFrame)
  end

  entry.canvas:replaceElements({
    type = "rectangle",
    action = "stroke",
    frame = {
      x = self.width / 2,
      y = self.width / 2,
      w = frame.w + self.offset * 2,
      h = frame.h + self.offset * 2,
    },
    roundedRectRadii = {xRadius = self.radius, yRadius = self.radius},
    strokeColor = color,
    strokeJoinStyle = "round",
    strokeWidth = self.width,
  })
  entry.canvas:show()
  entry.frame = {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
  entry.colorName = colorName
end

function LayoutBorders:refresh()
  if not self.enabled then return end
  local focused = self.focusedWindow()
  local focusedID = tonumber(call(focused, "id"))
  local present = {}
  for screenKey, layout in pairs(self.orchestrator:layoutSnapshot()) do
    for index, slot in ipairs(layout.slots) do
      local key = screenKey .. ":" .. tostring(index)
      local focusedSlot = slot.windowID == focusedID
      present[key] = true
      self:_draw(
        key,
        slot.frame,
        focusedSlot and self.focusColor or self.layoutColor,
        focusedSlot and "focus" or "layout"
      )
    end
  end
  local stale = {}
  for key in pairs(self.canvases) do
    if not present[key] then stale[#stale + 1] = key end
  end
  for _, key in ipairs(stale) do self:_delete(key) end
end

function LayoutBorders:start()
  if not self.enabled then return self end
  self.unsubscribe = self.orchestrator:subscribe(function() self:refresh() end)
  self:refresh()
  return self
end

function LayoutBorders:stop()
  if self.unsubscribe then self.unsubscribe(); self.unsubscribe = nil end
  local keys = {}
  for key in pairs(self.canvases) do keys[#keys + 1] = key end
  for _, key in ipairs(keys) do self:_delete(key) end
end

return LayoutBorders
