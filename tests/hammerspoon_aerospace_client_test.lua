-- Run from the repository root: lua tests/hammerspoon_aerospace_client_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local AerospaceClient = require("modules.aerospace_client")

local tasks = {}
local function taskNew(path, callback, arguments)
  local task = {path = path, callback = callback, arguments = arguments, running = false}
  function task:start() self.running = true; tasks[#tasks + 1] = self; return self end
  function task:isRunning() return self.running end
  function task:terminate() self.running = false end
  function task:finish(exitCode, stdout, stderr)
    self.running = false
    self.callback(exitCode, stdout or "", stderr or "")
  end
  return task
end

local function client(attributes)
  return AerospaceClient.new({executableCandidates = {"/aerospace"}}, {
    attributes = attributes or function() return true end,
    taskNew = taskNew,
    jsonDecode = function(value)
      if value == "valid" then return {{["window-id"] = 1}} end
      error("invalid")
    end,
    defer = function(callback) callback() end,
  })
end

local decoded, decodeError = AerospaceClient.decodeJSON("valid", function()
  return {{id = 1}}
end)
assert(decoded[1].id == 1 and not decodeError)
local invalid, invalidError = AerospaceClient.decodeJSON("broken", function() error("broken") end)
assert(not invalid and invalidError.kind == "invalid_json")

local unavailableResult
client(function() return nil end):run({"list-monitors"}, function(_, requestError)
  unavailableResult = requestError
end)
assert(unavailableResult.kind == "unavailable")

local nonzero
local active = client()
active:run({"workspace", "1"}, function(_, requestError) nonzero = requestError end)
tasks[#tasks]:finish(1, "", "command failed")
assert(nonzero.kind == "command_failed" and nonzero.exitCode == 1)

local invalidConfig
active:run({"reload-config"}, function(_, requestError) invalidConfig = requestError end)
tasks[#tasks]:finish(1, "", "Config error: invalid key")
assert(invalidConfig.kind == "invalid_config")

local firstError, secondOutput
active:run({"list-monitors"}, function(_, requestError) firstError = requestError end, {key = "state"})
local first = tasks[#tasks]
active:run({"list-monitors"}, function(output) secondOutput = output end, {key = "state"})
local second = tasks[#tasks]
first:finish(0, "old", "")
second:finish(0, "new", "")
assert(firstError.kind == "stale" and secondOutput == "new")

local records
active:query({"list-windows", "--all"}, function(value) records = value end, {format = "%{window-id}"})
assert(tasks[#tasks].arguments[#tasks[#tasks].arguments - 2] == "--json")
tasks[#tasks]:finish(0, "valid", "")
assert(records[1]["window-id"] == 1)

assert(AerospaceClient.shellCommand({"focus", "--window-id", "42"}) == "focus --window-id 42")
local safe = pcall(AerospaceClient.shellCommand, {"focus", "bad;command"})
assert(not safe)

print("Hammerspoon AeroSpace client tests passed")
