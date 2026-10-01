-- Run from the repository root: lua tests/hammerspoon_layout_borders_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local listener
local canvases = {}
local focusedWindowID = 1
local snapshots = {
  ["screen-1"] = {
    focusedSlot = 1,
    slots = {
      {windowID = 1, frame = {x = 10, y = 20, w = 600, h = 700}},
      {windowID = 2, frame = {x = 620, y = 20, w = 600, h = 700}},
    },
  },
}

local orchestrator = {}
function orchestrator:layoutSnapshot() return snapshots end
function orchestrator:focusedWindowID() return focusedWindowID end
function orchestrator:subscribe(callback)
  listener = callback
  return function() listener = nil end
end

local function canvasNew(frame)
  local canvas = {currentFrame = frame, frameChanges = 0}
  function canvas:level() return self end
  function canvas:behavior() return self end
  function canvas:clickActivating() return self end
  function canvas:frame(value)
    self.currentFrame = value
    self.frameChanges = self.frameChanges + 1
    return self
  end
  function canvas:replaceElements(element) self.element = element; return self end
  function canvas:show() self.visible = true; return self end
  function canvas:delete() self.deleted = true end
  canvases[#canvases + 1] = canvas
  return canvas
end

local LayoutBorders = require("modules.layout_borders")
local borders = LayoutBorders.new(orchestrator, {
  focusColor = {name = "focus"},
  layoutColor = {name = "layout"},
  offset = 2,
  width = 4.5,
}, {
  canvasBehavior = {},
  canvasLevel = 1,
  canvasNew = canvasNew,
}):start()

assert(#canvases == 2)
assert(canvases[1].element.strokeColor.name == "focus")
assert(canvases[2].element.strokeColor.name == "layout")
assert(canvases[1].element.strokeWidth == 4.5)
assert(canvases[1].currentFrame.x == 5.75 and canvases[1].currentFrame.w == 608.5)
assert(canvases[1].element.frame.x == 2.25 and canvases[1].element.frame.w == 604)

snapshots["screen-1"].focusedSlot = 2
focusedWindowID = 2
listener()
assert(#canvases == 2)
assert(canvases[1].element.strokeColor.name == "layout")
assert(canvases[2].element.strokeColor.name == "focus")
assert(canvases[1].frameChanges == 0 and canvases[2].frameChanges == 0)

snapshots["screen-1"].slots[2].windowID = 3
focusedWindowID = 3
listener()
assert(#canvases == 2)
assert(canvases[2].element.strokeColor.name == "focus")
assert(canvases[2].frameChanges == 0)

snapshots["screen-2"] = {
  focusedSlot = 1,
  slots = {
    {windowID = 4, frame = {x = 1240, y = 20, w = 600, h = 700}},
  },
}
focusedWindowID = 4
listener()
assert(#canvases == 3)
assert(canvases[1].element.strokeColor.name == "layout")
assert(canvases[2].element.strokeColor.name == "layout")
assert(canvases[3].element.strokeColor.name == "focus")

local focusedCanvases = 0
for _, canvas in ipairs(canvases) do
  if not canvas.deleted and canvas.element.strokeColor.name == "focus" then
    focusedCanvases = focusedCanvases + 1
  end
end
assert(focusedCanvases == 1, "only the globally focused slot may be Green")

snapshots["screen-1"].slots[2] = nil
listener()
assert(canvases[2].deleted)

borders:stop()
assert(listener == nil and canvases[1].deleted and canvases[3].deleted)

print("Hammerspoon layout border tests passed")
