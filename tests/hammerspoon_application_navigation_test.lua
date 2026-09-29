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
local repository = {
  listAll = function(_, callback) callback(records) end,
  matchingBundle = function(_, values, bundleID)
    local result = {}
    for _, value in ipairs(values) do if value.bundleID == bundleID then result[#result + 1] = value end end
    return result
  end,
  focusedRecord = function() return {id = 1, screen = "screen"} end,
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
local staleGeneration = gate:next()
gate:next()
appNavigation:_waitForWindow({bundleID = "example.app"}, {generation = staleGeneration}, false)
assert(activated == nil)

print("Hammerspoon application navigation tests passed")
