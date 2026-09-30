-- Run from the repository root: lua tests/hammerspoon_application_navigation_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

hs = {
  timer = {
    secondsSinceEpoch = function() return 0 end,
    doAfter = function(_, callback) callback() end,
  },
  notify = {new = function() return {send = function() end} end},
}

local ApplicationNavigation = require("modules.application_navigation")
local RequestGate = require("modules.request_gate")
local gate = RequestGate.new()
local activated
local chooserShown
local records = {{id = 9, bundleID = "example.app", appName = "Example", title = "Only"}}
local focusedWindow = {}
local repository = {
  listForBundle = function(_, bundleID, callback)
    assert(bundleID == "example.app")
    callback(records)
  end,
  focusedWindow = function() return focusedWindow end,
  record = function(_, window)
    return window == focusedWindow and {id = 1, screen = "screen"} or nil
  end,
}
local appNavigation = ApplicationNavigation.new({
  repository = repository,
  orchestrator = {
    activate = function(_, record) activated = record end,
    activeScreen = function() return "screen" end,
  },
  chooserFactory = function()
    return {show = function(_, choices, callback) chooserShown = choices; callback(choices[1]) end}
  end,
  gate = gate,
})

local generation = gate:next()
appNavigation:_showOrChoose(records, {generation = generation}, true)
assert(#chooserShown == 1 and activated.id == 9)

records = {
  {id = 9, bundleID = "example.app", appName = "Example", title = "First"},
  {id = 10, bundleID = "example.app", appName = "Example", title = "Second"},
}
appNavigation.chooserFactory = function()
  return {show = function(_, choices, callback) chooserShown = choices; callback(choices[2]) end}
end
appNavigation:_showOrChoose(records, {generation = generation}, true)
assert(#chooserShown == 2 and activated.id == 10)

activated = nil
appNavigation:activate({bundleID = "example.app"}, "single", false)
assert(activated.id == 9)

activated = nil
local staleGeneration = gate:next()
gate:next()
appNavigation:_waitForWindow({bundleID = "example.app"}, {generation = staleGeneration}, false)
assert(activated == nil)

print("Hammerspoon application navigation tests passed")
