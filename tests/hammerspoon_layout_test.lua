-- Run from the repository root: lua tests/hammerspoon_layout_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local planner = require("modules.layout_planner")
local RequestGate = require("modules.request_gate")

local frames = planner.frames({x = 0, y = 0, w = 1000, h = 800}, 3, 5)
assert(frames[1].x == 5 and frames[1].w == 492 and frames[1].h == 790)
assert(frames[2].x == 502 and frames[2].y == 5 and frames[2].h == 392)
assert(frames[3].x == 502 and frames[3].y == 402 and frames[3].h == 393)

local screen = {}
function screen:getUUID() return "screen-1" end
function screen:frame() return {x = 0, y = 0, w = 1000, h = 800} end

local application = {}
function application:isHidden() return false end
function application:unhide() self.hidden = false end

local windows = {}
local focused
local function newWindow(id)
  local window = {windowID = id, appliedFrames = {}}
  function window:id() return self.windowID end
  function window:isStandard() return true end
  function window:isFullScreen() return false end
  function window:isMinimized() return false end
  function window:application() return application end
  function window:screen() return screen end
  function window:setFrameWithWorkarounds(frame)
    self.frame = frame
    self.appliedFrames[#self.appliedFrames + 1] = frame
  end
  function window:focus() focused = self end
  function window:close() self.closed = true; windows[self.windowID] = nil end
  windows[id] = window
  return window
end

local first, second, third, fourth = newWindow(1), newWindow(2), newWindow(3), newWindow(4)
focused = first
local repository = {
  focusedWindow = function() return focused end,
  recordForID = function(_, id)
    local window = windows[id]
    return window and {id = id, window = window, screen = screen}
  end,
  record = function(_, window)
    return window and {id = window:id(), window = window, screen = screen}
  end,
  isUsable = function(_, window) return window and not window.closed end,
}

hs = {notify = {new = function() return {send = function() end} end}}
local LayoutOrchestrator = require("modules.layout_orchestrator")
local gate = RequestGate.new()
local orchestrator = LayoutOrchestrator.new(repository, gate, {
  gap = 5,
  restoreDelaySeconds = 0,
}, {
  after = function(_, callback) callback() end,
  mainScreen = function() return screen end,
})

local generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  generation = generation, mode = "single", screen = screen,
})
assert(orchestrator.layouts["screen-1"].ids[1] == 1)
assert(first.frame.x == 5 and first.frame.w == 990)

generation = gate:next()
orchestrator:activate({id = 2, window = second, screen = screen}, {
  anchorID = 1, generation = generation, mode = "stack", screen = screen,
})
assert(orchestrator.layouts["screen-1"].ids[1] == 1)
assert(orchestrator.layouts["screen-1"].ids[2] == 2)
assert(first.frame.w == 492 and second.frame.x == 502)

generation = gate:next()
orchestrator:activate({id = 3, window = third, screen = screen}, {
  anchorID = 2, generation = generation, mode = "stack", screen = screen,
})
focused = second
orchestrator:rotatePositions()
local layout = orchestrator.layouts["screen-1"]
assert(layout.ids[1] == 2 and layout.ids[2] == 3 and layout.ids[3] == 1,
  table.concat(layout.ids, ","))
assert(focused == third)

orchestrator:focusNext()
assert(focused == first)

focused = fourth
generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  anchorID = 4, generation = generation, mode = "stack", screen = screen,
})
layout = orchestrator.layouts["screen-1"]
assert(#layout.ids == 2 and layout.ids[1] == 4 and layout.ids[2] == 1,
  table.concat(layout.ids, ","))

print("Hammerspoon layout planning tests passed")
