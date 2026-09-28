-- Run from the repository root: lua tests/hammerspoon_layout_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local planner = require("modules.layout_planner")

local function joined(commands)
  local result = {}
  for _, command in ipairs(commands) do result[#result + 1] = table.concat(command, " ") end
  return table.concat(result, "\n")
end

local target = {id = 3, workspace = "2", tiled = true}
local windows = {
  {id = 1, workspace = "1", tiled = true},
  {id = 2, workspace = "1", tiled = true},
}

local single = joined(planner.activation(target, "1", windows, "10", "single"))
assert(single:find("move-node-to-workspace --window-id 1 10", 1, true))
assert(single:find("move-node-to-workspace --window-id 2 10", 1, true))
assert(single:find("layout --workspace 1 --root h_tiles", 1, true))
assert(single:find("focus --window-id 3", 1, true))

local one = joined(planner.activation(target, "1", {}, "10", "stack"))
assert(not one:find("join-with", 1, true))

local two = joined(planner.activation(target, "1", {{id = 1, tiled = true}}, "10", "stack"))
assert(not two:find("join-with", 1, true))

local three = joined(planner.activation(target, "1", windows, "10", "stack"))
assert(three:find("join-with --window-id 2 right", 1, true))
assert(three:find("layout --window-id 2 v_tiles", 1, true))

local manyWindows = {
  {id = 1, tiled = true}, {id = 2, tiled = true}, {id = 4, tiled = true},
}
local many = joined(planner.activation(target, "1", manyWindows, "10", "stack"))
local _, joins = many:gsub("join%-with", "")
assert(joins == 2)
assert(many:find("join-with --window-id 2 right", 1, true))
assert(many:find("join-with --window-id 4 right", 1, true))

local parking = joined(planner.activation(target, "10", windows, "10", "single"))
assert(not parking:find("--window-id 1 10", 1, true))

local configFile = assert(io.open("home/.aerospace.toml", "r"))
local config = configFile:read("*a")
configFile:close()
assert(config:find('2 = ["secondary", "main"]', 1, true))
assert(config:find('persistent-workspaces = ["1", "2", "10"]', 1, true))

print("Hammerspoon layout planning tests passed")
