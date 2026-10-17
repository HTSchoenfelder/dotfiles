-- Run from the repository root: lua tests/hammerspoon_layout_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local planner = require("modules.layout_planner")
local RequestGate = require("modules.request_gate")
local LayoutOrchestrator = require("modules.layout_orchestrator")

local half = planner.frames({x = 0, y = 0, w = 1000, h = 800}, 2, 5, 0.5)
local wide = planner.frames({x = 0, y = 0, w = 1000, h = 800}, 2, 5, 0.7)
assert(half[1].w == 492 and half[2].x == 502)
assert(wide[1].w == 689 and wide[2].x == 699)

local function fixture()
  local firstScreen = {uuid = "first", x = 0}
  local secondScreen = {uuid = "second", x = 1000}
  for _, screen in ipairs({firstScreen, secondScreen}) do
    function screen:getUUID() return self.uuid end
    function screen:frame() return {x = self.x, y = 0, w = 1000, h = 800} end
  end
  local windows, focused, rank = {}, nil, {}
  local application = {isHidden = function() return false end,
    bundleID = function() return "example.app" end}
  local function add(id, screen)
    local window = {number = id, display = screen, currentFrame = {x = screen.x + 30, y = 30, w = 400, h = 300}}
    function window:id() return self.number end
    function window:screen() return self.display end
    function window:frame() return self.currentFrame end
    function window:application() return application end
    function window:isMinimized() return false end
    function window:focus() focused = self end
    function window:close() self.closed = true; windows[id] = nil; if focused == self then focused = nil end end
    function window:setFrameWithWorkarounds(frame)
      self.currentFrame = frame
      self.display = frame.x >= 1000 and secondScreen or firstScreen
    end
    windows[id] = window
    rank[id] = id
    return window
  end
  local repository = {
    focusedWindow = function() return focused end,
    isUsable = function(_, window) return window and not window.closed end,
    recordForID = function(_, id)
      local window = windows[id]
      return window and {id = id, window = window, screen = window:screen(),
        screenID = window:screen():getUUID()}
    end,
    listAll = function(_, callback)
      local records = {}
      for id, window in pairs(windows) do
        records[#records + 1] = {id = id, window = window,
          screen = window:screen(), screenID = window:screen():getUUID()}
      end
      callback(records)
    end,
    orderedByHistory = function(_, records)
      table.sort(records, function(a, b) return rank[a.id] < rank[b.id] end)
      return records
    end,
  }
  local filter = {subscribe = function() end, unsubscribeAll = function() end}
  local watcher = {start = function(self) return self end, stop = function() end}
  hs = {printf = function() end}
  local gate = RequestGate.new()
  local orchestrator = LayoutOrchestrator.new(repository, gate, {gap = 5, restoreDelaySeconds = 0}, {
    after = function(_, callback) callback() end,
    mainScreen = function() return firstScreen end,
    filterNew = function() return filter end,
    screenWatcherNew = function() return watcher end,
    events = {created = "created", destroyed = "destroyed", focused = "focused",
      moved = "moved", notInCurrentSpace = "notInCurrentSpace", notVisible = "notVisible"},
  })
  local function select(window, mode)
    orchestrator:activate({id = window:id(), window = window}, orchestrator:capture(mode, gate:next()))
  end
  return {first = firstScreen, second = secondScreen, add = add, select = select,
    focus = function(window) focused = window end, focused = function() return focused end,
    rank = rank, gate = gate, orchestrator = orchestrator}
end

local session = fixture()
local left = session.add(1, session.first)
local parked = session.add(2, session.first)
local older = session.add(3, session.first)
session.focus(left)
session.select(parked, "focused")
local layout = session.orchestrator.layouts.first
assert(layout.wanted == 1 and layout.slots[1].windowID == 2)
assert(left:screen() == session.first and session.focused() == parked)
-- The unselected window stays native and remains a refill candidate.
session.select(older, "other")
assert(layout.wanted == 2 and layout.slots[1].windowID == 2 and layout.slots[2].windowID == 3)
assert(session.focused() == parked and parked:frame().w == 689)
session.orchestrator:focusNext()
assert(session.focused() == older)
session.orchestrator:rotatePositions()
assert(layout.slots[1].windowID == 3 and layout.slots[2].windowID == 2)
assert(session.focused() == parked)
session.orchestrator:toggleRatio()
assert(layout.ratio == 0.5 and older:frame().w == 492)
session.orchestrator:keepOnly()
assert(layout.wanted == 1 and layout.slots[1].windowID == 2)
session.orchestrator:enableTwo()
assert(layout.wanted == 2 and layout.slots[2].windowID == 1)
assert(session.focused() == parked)

local remote = session.add(4, session.second)
session.select(remote, "focused")
assert(layout.slots[1].windowID == 4 and remote:screen() == session.first)
assert(session.orchestrator.layouts.first.slots[2].windowID == 1)
assert(session.orchestrator.layouts.second == nil)
session.orchestrator:switchScreen(session.second)
local empty = session.orchestrator:layoutSnapshot().second
assert(empty.active and empty.focusedSlot == 1 and empty.slots[1].windowID == nil)
assert(session.orchestrator:activeScreen() == session.second)
session.select(left, "focused")
assert(session.orchestrator.layouts.second.slots[1].windowID == 1)
assert(left:screen() == session.second)

local closing = fixture()
local master = closing.add(11, closing.first)
local peer = closing.add(12, closing.first)
local replacement = closing.add(13, closing.first)
closing.rank[13] = 0
closing.focus(master)
closing.select(peer, "other")
closing.orchestrator:closeFocused()
assert(closing.orchestrator.layouts.first.slots[1].windowID == 13)
assert(closing.orchestrator.layouts.first.slots[2].windowID == 12)
assert(closing.focused() == replacement)

local vacant = fixture()
local current = vacant.add(21, vacant.first)
vacant.focus(current)
vacant.orchestrator:capture("focused", vacant.gate:next())
vacant.orchestrator:enableTwo()
local state = vacant.orchestrator.layouts.first
assert(state.wanted == 2 and state.slots[2].windowID == nil)
assert(current:frame().w == 990)
vacant.orchestrator:closeFocused()
assert(state.wanted == 2 and state.slots[1].windowID == nil
  and state.slots[2].windowID == nil)
assert(vacant.orchestrator:layoutSnapshot().first.active)

local exchange = fixture()
local localWindow = exchange.add(31, exchange.first)
local remoteWindow = exchange.add(32, exchange.second)
exchange.focus(localWindow)
exchange.orchestrator:capture("focused", exchange.gate:next())
exchange.orchestrator:switchScreen(exchange.second)
assert(exchange.orchestrator.layouts.second.slots[1].windowID == 32)
exchange.select(remoteWindow, "focused")
exchange.orchestrator:switchScreen(exchange.first)
exchange.select(remoteWindow, "focused")
assert(exchange.orchestrator.layouts.first.slots[1].windowID == 32)
assert(exchange.orchestrator.layouts.second.slots[1].windowID == nil)
assert(remoteWindow:screen() == exchange.first and localWindow:screen() == exchange.first)

local newlyOpened = fixture()
local initial = newlyOpened.add(41, newlyOpened.first)
newlyOpened.focus(initial)
newlyOpened.orchestrator:capture("focused", newlyOpened.gate:next())
newlyOpened.orchestrator:enableTwo()
local incoming = newlyOpened.add(42, newlyOpened.first)
newlyOpened.orchestrator:_created(incoming)
assert(newlyOpened.orchestrator.layouts.first.slots[2].windowID == 42)
assert(newlyOpened.orchestrator.layouts.first.slots[1].windowID == 41)
assert(newlyOpened.focused() == initial)

local emptyScreen = fixture()
local original = emptyScreen.add(51, emptyScreen.first)
emptyScreen.focus(original)
emptyScreen.orchestrator:capture("focused", emptyScreen.gate:next())
emptyScreen.orchestrator:switchScreen(emptyScreen.second)
local destination = emptyScreen.orchestrator:layoutSnapshot().second
assert(destination.active and destination.slots[1].frame.w == 990)
assert(emptyScreen.focused() == original)
local selected = emptyScreen.add(52, emptyScreen.first)
emptyScreen.select(selected, "focused")
assert(selected:screen() == emptyScreen.second)
assert(emptyScreen.orchestrator.layouts.second.slots[1].windowID == 52)

local externalClose = fixture()
local prior = externalClose.add(61, externalClose.first)
local nextWindow = externalClose.add(62, externalClose.first)
externalClose.focus(prior)
externalClose.orchestrator:capture("focused", externalClose.gate:next())
prior:close()
externalClose.orchestrator:_validateLifecycle(prior)
assert(externalClose.orchestrator.layouts.first.slots[1].windowID == 62)
assert(externalClose.focused() == nextWindow)

print("Hammerspoon slot layout tests passed")
