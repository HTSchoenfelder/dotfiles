-- Run from the repository root: lua tests/hammerspoon_navigation_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local WindowHistory = require("modules.window_history")
local WindowRepository = require("modules.window_repository")
local RequestGate = require("modules.request_gate")

local history = WindowHistory.new()
history:seed({3, 2, 1})
history:remember(2)
local ordered = history:sort({{id = 1}, {id = 2}, {id = 3}, {id = 4}})
assert(ordered[1].id == 2)
assert(ordered[2].id == 3 and ordered[3].id == 1)
assert(ordered[4].id == 4)

local screen = {}
function screen:getUUID() return "display" end
local application = {}
function application:bundleID() return "example.app" end
function application:name() return "Example" end
local window = {}
function window:id() return 42 end
function window:isStandard() return true end
function window:isFullScreen() return false end
function window:isMinimized() return false end
function window:title() return "Title" end
function window:application() return application end
function window:screen() return screen end

local normalized = WindowRepository.windowRecord(window)
assert(normalized.id == 42 and normalized.bundleID == "example.app")
assert(normalized.screenID == "display" and normalized.window == window)

local secondWindow = setmetatable({}, {__index = window})
function secondWindow:id() return 2 end
local repository = WindowRepository.new(history, {
  orderedWindows = function() return {window, secondWindow} end,
  allWindows = function() return {secondWindow, window} end,
  focusedWindow = function() return secondWindow end,
})
local records
repository:listAll(function(values) records = values end)
assert(#records == 2 and repository:focusedRecord(records).id == 2)
local matches = repository:matchingBundle(records, "example.app")
assert(#matches == 2)

local gate = RequestGate.new()
local first = gate:next()
local second = gate:next()
assert(not gate:isCurrent(first) and gate:isCurrent(second))

local definitions = require("apps")
local byKey = {}
for _, definition in ipairs(definitions) do byKey[definition.key] = definition end
assert(byKey.i.bundleID == "com.google.Chrome.app.pommaclcbfghclhalboakcipcmmndhcj")
assert(byKey.j.launchEnvironment.START_ZELLIJ == "1")

local WindowNavigation = require("modules.window_navigation")
local filtered
local fakeRepository = {
  listAll = function(_, callback)
    callback({
      {id = 10, bundleID = "a", appName = "A", title = "One"},
      {id = 11, bundleID = "a", appName = "A", title = "Two"},
      {id = 12, bundleID = "b", appName = "B", title = "Three"},
    })
  end,
  focusedRecord = function()
    return {id = 10, bundleID = "a", appName = "A", title = "One"}
  end,
  orderedByHistory = function(_, values) return values end,
}
local windowNavigation = WindowNavigation.new({
  repository = fakeRepository,
  gate = RequestGate.new(),
  orchestrator = {},
  allScreens = function() return {} end,
})
windowNavigation:commaItems(true, function(items) filtered = items end)
assert(#filtered == 2 and filtered[1].id == 10 and filtered[2].id == 11)

print("Hammerspoon navigation tests passed")
