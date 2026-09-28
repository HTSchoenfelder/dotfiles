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

local normalized = WindowRepository.normalize({
  ["window-id"] = 42,
  ["app-bundle-id"] = "example.app",
  ["app-name"] = "Example",
  ["window-title"] = "Title",
  ["window-parent-container-layout"] = "h_tiles",
  workspace = "1",
  ["workspace-is-focused"] = true,
  ["workspace-is-visible"] = true,
  ["monitor-id"] = 2,
})
assert(normalized.id == 42 and normalized.bundleID == "example.app")
assert(normalized.tiled and normalized.workspaceFocused and normalized.workspaceVisible)

local repository = WindowRepository.new({}, history, {
  getWindow = function() return nil end,
  focusedWindow = function() return {id = function() return 2 end} end,
})
local records = {{id = 1, bundleID = "a"}, {id = 2, bundleID = "b"}, {id = 3, bundleID = "a"}}
assert(repository:focusedRecord(records).id == 2)
local matches = repository:matchingBundle(records, "a")
assert(#matches == 2 and matches[1].bundleID == "a")

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
local executed
local fakeRepository = {
  listAll = function(_, callback)
    callback({
      {id = 10, bundleID = "a", appName = "A", title = "One", workspace = "1", tiled = true},
      {id = 11, bundleID = "a", appName = "A", title = "Two", workspace = "1", tiled = true},
      {id = 12, bundleID = "b", appName = "B", title = "Three", workspace = "1", tiled = true},
      {id = 13, bundleID = "a", appName = "A", title = "Dialog", workspace = "1", tiled = false},
    })
  end,
  focusedRecord = function()
    return {id = 10, bundleID = "a", appName = "A", title = "One", workspace = "1", tiled = true}
  end,
  orderedByHistory = function(_, values) return values end,
}
local fakeClient = {
  execute = function(_, command) executed = command end,
}
local windowNavigation = WindowNavigation.new({
  client = fakeClient,
  repository = fakeRepository,
  gate = RequestGate.new(),
  workspaces = {terminal = "1"},
})
windowNavigation:rotatePositions()
assert(table.concat(executed, " ") ==
  "swap --window-id 10 --swap-focus --wrap-around dfs-next")

local filtered
windowNavigation:commaItems(true, function(items) filtered = items end)
assert(#filtered == 2 and filtered[1].id == 10 and filtered[2].id == 11)

print("Hammerspoon navigation tests passed")
