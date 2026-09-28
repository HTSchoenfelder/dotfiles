-- Run from the repository root: lua tests/hammerspoon_application_navigation_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local now = 0
hs = {
  timer = {
    secondsSinceEpoch = function() return now end,
    doAfter = function(_, callback) callback() end,
  },
  notify = {new = function() return {send = function() end} end},
}

local ApplicationNavigation = require("modules.application_navigation")
local RequestGate = require("modules.request_gate")
local gate = RequestGate.new()
local activated
local chooserShown
local moved
local records = {{id = 9, bundleID = "example.app", appName = "Example", title = "Only", workspace = "2"}}
local repository = {
  listAll = function(_, callback) callback(records) end,
  matchingBundle = function(_, values, bundleID)
    local result = {}
    for _, value in ipairs(values) do if value.bundleID == bundleID then result[#result + 1] = value end end
    return result
  end,
  focusedRecord = function() return {workspace = "1"} end,
}
local appNavigation = ApplicationNavigation.new({
  client = {moveWindowToWorkspace = function(_, id, workspace) moved = {id, workspace} end},
  repository = repository,
  orchestrator = {activate = function(_, record) activated = record end},
  chooserFactory = function()
    return {show = function(_, choices, callback) chooserShown = choices; callback(choices[1]) end}
  end,
  gate = gate,
  workspaces = {terminal = "1", parking = "10"},
})

local generation = gate:next()
appNavigation:_showOrChoose(records, {generation = generation}, true)
assert(#chooserShown == 1 and activated.id == 9)

records = {
  {id = 9, bundleID = "example.app", appName = "Example", title = "First", workspace = "2"},
  {id = 10, bundleID = "example.app", appName = "Example", title = "Second", workspace = "2"},
}
appNavigation.chooserFactory = function()
  return {show = function(_, choices, callback) chooserShown = choices; callback(choices[2]) end}
end
appNavigation:_showOrChoose(records, {generation = generation}, true)
assert(#chooserShown == 2 and activated.id == 10)

activated = nil
records = {{id = 9, bundleID = "example.app", appName = "Example", title = "Only", workspace = "2"}}
local staleGeneration = gate:next()
gate:next()
appNavigation:_waitForWindow({bundleID = "example.app"}, {
  generation = staleGeneration,
}, false, {})
assert(moved[1] == 9 and moved[2] == "10" and activated == nil)

print("Hammerspoon application navigation tests passed")
