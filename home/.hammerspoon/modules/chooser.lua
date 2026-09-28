local Chooser = {}
Chooser.__index = Chooser

local function activeScreen()
  local focused = hs.window.focusedWindow()
  return focused and focused:screen() or hs.screen.mainScreen()
end

function Chooser.new(options)
  options = options or {}
  local self = setmetatable({
    rows = options.rows or 7,
    width = options.width or 40,
    callback = nil,
  }, Chooser)
  self.instance = hs.chooser.new(function(choice)
    local callback = self.callback
    self.callback = nil
    if callback then callback(choice) end
  end)
  self.instance:rows(self.rows)
  self.instance:width(self.width)
  self.instance:searchSubText(false)
  self.instance:placeholderText("")
  return self
end

function Chooser:show(choices, callback, screen)
  self.callback = callback
  self.instance:choices(choices)
  self.instance:query("")
  screen = screen or activeScreen()
  local frame = screen and screen:frame()
  if frame then
    local estimatedWidth = math.min(720, frame.w * self.width / 100)
    local estimatedHeight = math.min(self.rows, math.max(1, #choices)) * 48 + 56
    self.instance:show({
      x = frame.x + (frame.w - estimatedWidth) / 2,
      y = frame.y + (frame.h - estimatedHeight) / 2,
    })
  else
    self.instance:show()
  end
end

function Chooser:hide()
  self.instance:hide()
end

function Chooser:isVisible()
  return self.instance:isVisible()
end

function Chooser:selectedRow(row)
  self.instance:selectedRow(row)
end

function Chooser:select(row)
  self.instance:select(row)
end

return Chooser
