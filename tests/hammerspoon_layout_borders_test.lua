-- Run from the repository root: lua tests/hammerspoon_layout_borders_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local focused
local records = {}
local listener
local canvases = {}
local subscribedEvents
local unsubscribed = false

local function window(id, frame)
  local value = {windowID = id, currentFrame = frame}
  function value:id() return self.windowID end
  function value:frame() return self.currentFrame end
  return value
end

local first = window(1, {x = 10, y = 20, w = 600, h = 700})
local second = window(2, {x = 620, y = 20, w = 600, h = 700})
focused = first
records = {{id = 1, window = first}, {id = 2, window = second}}

local orchestrator = {}
function orchestrator:layoutWindows() return records end
function orchestrator:subscribe(callback)
  listener = callback
  return function() listener = nil end
end

local function canvasNew(frame)
  local canvas = {currentFrame = frame}
  function canvas:level() return self end
  function canvas:behavior() return self end
  function canvas:clickActivating() return self end
  function canvas:frame(value) self.currentFrame = value; return self end
  function canvas:replaceElements(element) self.element = element; return self end
  function canvas:show() self.visible = true; return self end
  function canvas:delete() self.deleted = true end
  canvases[#canvases + 1] = canvas
  return canvas
end

local filter = {}
function filter:subscribe(events, callback)
  subscribedEvents = events
  self.callback = callback
end
function filter:unsubscribeAll() unsubscribed = true end

local LayoutBorders = require("modules.layout_borders")
local borders = LayoutBorders.new(orchestrator, {
  activeColor = {name = "active"},
  inactiveColor = {name = "inactive"},
  offset = 2,
  width = 4,
}, {
  canvasBehavior = {},
  canvasLevel = 1,
  canvasNew = canvasNew,
  events = {"focused", "moved", "destroyed"},
  filterNew = function() return filter end,
  focusedWindow = function() return focused end,
}):start()

assert(#canvases == 2 and #subscribedEvents == 3)
assert(canvases[1].element.strokeColor.name == "active")
assert(canvases[2].element.strokeColor.name == "inactive")
assert(canvases[1].currentFrame.x == 6 and canvases[1].currentFrame.w == 608)
assert(canvases[1].element.frame.x == 2 and canvases[1].element.frame.w == 604)

focused = second
filter.callback()
assert(canvases[1].element.strokeColor.name == "inactive")
assert(canvases[2].element.strokeColor.name == "active")

records = {{id = 2, window = second}}
listener()
assert(canvases[1].deleted)

borders:stop()
assert(unsubscribed and listener == nil and canvases[2].deleted)

print("Hammerspoon layout border tests passed")
