local Chooser = {}
Chooser.__index = Chooser

local function activeScreen()
  local focused = hs.window.focusedWindow()
  return focused and focused:screen() or hs.screen.mainScreen()
end

function Chooser.new(options)
  options = options or {}
  local self = setmetatable({
    dark = options.dark,
    foregroundColor = options.foregroundColor,
    rows = options.rows or 7,
    searchSubText = options.searchSubText == true,
    secondaryColor = options.secondaryColor,
    showWindowTitles = options.showWindowTitles ~= false,
    width = options.width or 40,
    callback = nil,
    originalChoices = {},
  }, Chooser)
  self.instance = hs.chooser.new(function(choice)
    local callback = self.callback
    local original = choice and self.originalChoices[tonumber(choice.uuid)] or nil
    self.callback = nil
    self.originalChoices = {}
    if callback then callback(original) end
  end)
  self.instance:rows(self.rows)
  self.instance:width(self.width)
  self.instance:searchSubText(self.searchSubText)
  self.instance:placeholderText("")
  if self.dark ~= nil then self.instance:bgDark(self.dark) end
  if self.foregroundColor then self.instance:fgColor(self.foregroundColor) end
  if self.secondaryColor then self.instance:subTextColor(self.secondaryColor) end
  return self
end

function Chooser:show(choices, callback, screen)
  self.callback = callback
  self.originalChoices = choices
  local displayChoices = {}
  for index, choice in ipairs(choices) do
    local subText = choice.subText
    if choice.kind == "window" and not self.showWindowTitles then subText = nil end
    displayChoices[index] = {
      text = choice.text,
      subText = subText,
      image = choice.image,
      valid = choice.valid,
      uuid = tostring(index),
    }
  end
  self.instance:choices(displayChoices)
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
