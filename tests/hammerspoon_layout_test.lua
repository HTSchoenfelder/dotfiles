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
local secondScreen = {}
function secondScreen:getUUID() return "screen-2" end
function secondScreen:frame() return {x = 1000, y = 0, w = 1000, h = 800} end

local application = {}
function application:isHidden() return false end
function application:unhide() self.hidden = false end

local windows = {}
local focused
local function newWindow(id, initialScreen)
  local window = {
    windowID = id,
    appliedFrames = {},
    currentFrame = {x = 20, y = 20, w = 400, h = 300},
    currentScreen = initialScreen or screen,
  }
  function window:id() return self.windowID end
  function window:isStandard() return true end
  function window:isFullScreen() return false end
  function window:isMinimized() return self.minimized == true end
  function window:unminimize() self.minimized = false end
  function window:isVisible() return not self.closed end
  function window:application() return application end
  function window:screen() return self.currentScreen end
  function window:frame() return self.currentFrame end
  function window:setFrameWithWorkarounds(frame)
    self.focusedBeforeFrame = focused == self
    self.currentFrame = {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
    self.currentScreen = frame.x >= 1000 and secondScreen or screen
    self.appliedFrames[#self.appliedFrames + 1] = self.currentFrame
  end
  function window:focus()
    self.focusCalls = (self.focusCalls or 0) + 1
    focused = self
  end
  function window:close() self.closed = true; windows[self.windowID] = nil end
  windows[id] = window
  return window
end

local first = newWindow(1)
local second = newWindow(2)
local third = newWindow(3)
local fourth = newWindow(4)
local fifth = newWindow(5, secondScreen)
local sixth = newWindow(6, secondScreen)
local seventh = newWindow(7)
focused = first

local repository = {
  focusedWindow = function() return focused end,
  recordForID = function(_, id)
    local window = windows[id]
    return window and {id = id, window = window, screen = window:screen()}
  end,
  record = function(_, window)
    return window and {id = window:id(), window = window, screen = window:screen()}
  end,
  borderRecord = function(_, window)
    return window and not window.closed
      and {id = window:id(), window = window, screen = window:screen(), minimized = false}
      or nil
  end,
  isUsable = function(_, window) return window and not window.closed end,
}

local filter = {}
function filter:subscribe(events, callback) self.events = events; self.callback = callback end
function filter:unsubscribeAll() self.unsubscribed = true end
local watcher = {}
function watcher:start() self.started = true; return self end
function watcher:stop() self.stopped = true end

hs = {printf = function() end}
local LayoutOrchestrator = require("modules.layout_orchestrator")
local gate = RequestGate.new()
local scheduledDelays = {}
local orchestrator = LayoutOrchestrator.new(repository, gate, {
  gap = 5,
  restoreDelaySeconds = 0,
  validationDelaySeconds = 0,
}, {
  after = function(delay, callback)
    scheduledDelays[#scheduledDelays + 1] = delay
    callback()
  end,
  events = {
    destroyed = "destroyed",
    focused = "focused",
    moved = "moved",
    notInCurrentSpace = "notInCurrentSpace",
    notVisible = "notVisible",
  },
  filterNew = function() return filter end,
  mainScreen = function() return screen end,
  screenWatcherNew = function(callback) watcher.callback = callback; return watcher end,
})
local layoutChanges = 0
local unsubscribe = orchestrator:subscribe(function() layoutChanges = layoutChanges + 1 end)

local function slotIDs(layout)
  local ids = {}
  for _, slot in ipairs(layout.slots) do ids[#ids + 1] = slot.windowID end
  return table.concat(ids, ",")
end

local function assertLayoutInvariants()
  local seen = {}
  for _, currentLayout in pairs(orchestrator.layouts) do
    assert(#currentLayout.slots > 0)
    assert(currentLayout.focusedSlot >= 1 and currentLayout.focusedSlot <= #currentLayout.slots)
    for _, slot in ipairs(currentLayout.slots) do
      assert(not seen[slot.windowID], "window belongs to more than one layout")
      assert(slot.frame and slot.frame.x and slot.frame.y and slot.frame.w and slot.frame.h)
      seen[slot.windowID] = true
    end
  end
end

local generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  generation = generation, mode = "single", screen = screen,
})
assert(orchestrator.layouts["screen-1"].slots[1].windowID == 1)
assert(first:frame().x == 5 and first:frame().w == 990)
assert(#scheduledDelays == 0 and layoutChanges == 1)
assertLayoutInvariants()

local firstFrameCount, firstFocusCount = #first.appliedFrames, first.focusCalls
generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  generation = generation, mode = "single", screen = screen,
})
assert(#first.appliedFrames == firstFrameCount and first.focusCalls == firstFocusCount)
assertLayoutInvariants()

generation = gate:next()
orchestrator:activate({id = 2, window = second, screen = screen}, {
  anchorID = 1, generation = generation, mode = "stack", screen = screen,
})
assert(slotIDs(orchestrator.layouts["screen-1"]) == "1,2")
assert(first:frame().w == 492 and second:frame().x == 502 and not second.focusedBeforeFrame)
assertLayoutInvariants()

second.minimized = true
local prepared = false
orchestrator:_prepare(second, function() prepared = true end)
assert(prepared and not second.minimized and focused == second)
assert(scheduledDelays[#scheduledDelays] == 0)

generation = gate:next()
orchestrator:activate({id = 3, window = third, screen = screen}, {
  anchorID = 2, generation = generation, mode = "stack", screen = screen,
})
focused = second
orchestrator:rotatePositions()
local layout = orchestrator.layouts["screen-1"]
assert(slotIDs(layout) == "2,3,1", slotIDs(layout))
assert(focused == third)
assertLayoutInvariants()

orchestrator:focusNext()
assert(focused == first)

focused = fourth
generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  anchorID = 4, generation = generation, mode = "stack", screen = screen,
})
layout = orchestrator.layouts["screen-1"]
assert(slotIDs(layout) == "4,1", slotIDs(layout))
assertLayoutInvariants()

orchestrator.layouts["screen-2"] = {
  screen = secondScreen,
  focusedSlot = 1,
  slots = {{windowID = 5, frame = fifth:frame()}},
}
focused = first
generation = gate:next()
orchestrator:activate({id = 1, window = first, screen = screen}, {
  generation = generation, mode = "stack", screen = secondScreen,
})
local secondLayout = orchestrator.layouts["screen-2"]
assert(slotIDs(secondLayout) == "5,1")
assert(first:screen() == secondScreen and fifth:screen() == secondScreen)
assertLayoutInvariants()

generation = gate:next()
orchestrator:activate({id = 2, window = second, screen = screen}, {
  generation = generation, mode = "single", screen = secondScreen,
})
assert(slotIDs(secondLayout) == "2")
assert(second:screen() == secondScreen)
assertLayoutInvariants()

generation = gate:next()
orchestrator:activate({id = 5, window = fifth, screen = secondScreen}, {
  anchorID = 2, generation = generation, mode = "stack", screen = secondScreen,
})
local retainedFrame = secondLayout.slots[2].frame
generation = gate:next()
orchestrator:adopt({id = 6, window = sixth, screen = secondScreen}, generation)
assert(slotIDs(secondLayout) == "2,6")
assert(secondLayout.slots[2].frame.x == retainedFrame.x
  and secondLayout.slots[2].frame.y == retainedFrame.y
  and secondLayout.slots[2].frame.w == retainedFrame.w
  and secondLayout.slots[2].frame.h == retainedFrame.h)
assert(sixth:frame().x == retainedFrame.x and focused == sixth)
assertLayoutInvariants()

generation = gate:next()
orchestrator:adopt({id = 2, window = second, screen = secondScreen}, generation)
assert(slotIDs(secondLayout) == "2,6" and secondLayout.focusedSlot == 1)
assert(focused == second)
assertLayoutInvariants()

orchestrator:clearScreen(screen)
generation = gate:next()
orchestrator:adopt({id = 4, window = fourth, screen = screen}, generation)
assert(slotIDs(orchestrator.layouts["screen-1"]) == "4")
assert(fourth:frame().w == 990)
assertLayoutInvariants()

focused = seventh
orchestrator:_validateFocus()
assert(orchestrator.layouts["screen-1"] == nil)
assert(orchestrator.layouts["screen-2"] == secondLayout)

focused = sixth
sixth.currentFrame.x = sixth.currentFrame.x + 30
orchestrator:_validateMove(sixth)
assert(orchestrator.layouts["screen-2"] == nil)

orchestrator:start()
assert(filter.callback and watcher.started)
watcher.callback()
orchestrator:stop()
assert(filter.unsubscribed and watcher.stopped and orchestrator.observer.filter == nil)

local previousChanges = layoutChanges
unsubscribe()
orchestrator:_notify()
assert(layoutChanges == previousChanges)

print("Hammerspoon layout planning tests passed")
