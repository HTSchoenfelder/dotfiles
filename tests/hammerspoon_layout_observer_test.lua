-- Run from the repository root: lua tests/hammerspoon_layout_observer_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local timers = {}
local calls = {focus = 0, lifecycle = 0, move = 0, screens = 0}

local filter = {}
function filter:subscribe(events, callback) self.events = events; self.callback = callback end
function filter:unsubscribeAll() self.unsubscribed = true end

local watcher = {}
function watcher:start() self.started = true; return self end
function watcher:stop() self.stopped = true end

local window = {}
function window:id() return 42 end

local LayoutObserver = require("modules.layout_observer")
local observer = LayoutObserver.new({
  onFocus = function() calls.focus = calls.focus + 1 end,
  onLifecycle = function(candidate)
    assert(candidate == window)
    calls.lifecycle = calls.lifecycle + 1
  end,
  onMove = function(candidate)
    assert(candidate == window)
    calls.move = calls.move + 1
  end,
  onScreensChanged = function() calls.screens = calls.screens + 1 end,
}, {validationDelaySeconds = 0.08}, {
  after = function(delay, callback)
    assert(delay == 0.08)
    timers[#timers + 1] = callback
  end,
  events = {
    destroyed = "destroyed",
    focused = "focused",
    moved = "moved",
    notInCurrentSpace = "notInCurrentSpace",
    notVisible = "notVisible",
  },
  filterNew = function() return filter end,
  screenWatcherNew = function(callback) watcher.callback = callback; return watcher end,
}):start()

assert(filter.callback and watcher.started and #filter.events == 5)

filter.callback(window, nil, "focused")
filter.callback(window, nil, "focused")
timers[1]()
timers[2]()
assert(calls.focus == 1)

filter.callback(window, nil, "moved")
filter.callback(window, nil, "moved")
timers[3]()
timers[4]()
assert(calls.move == 1)

filter.callback(window, nil, "destroyed")
timers[5]()
assert(calls.lifecycle == 1)

watcher.callback()
assert(calls.screens == 1)

observer:stop()
assert(filter.unsubscribed and watcher.stopped)

print("Hammerspoon layout observer tests passed")
