-- Run from the repository root: lua tests/hammerspoon_application_groups_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local taps = {}
hs = {
  image = {imageFromAppBundle = function(bundleID) return bundleID end},
  eventtap = {
    event = {types = {flagsChanged = 1}},
    new = function(_, callback)
      local tap = {callback = callback}
      function tap:start() self.running = true end
      function tap:stop() self.running = false end
      taps[#taps + 1] = tap
      return tap
    end,
  },
  timer = {doAfter = function(_, callback) callback() end},
}

local CommaSelection = require("modules.comma_selection")
local ApplicationGroups = require("modules.application_groups")
local RequestGate = require("modules.request_gate")

local chooser
local comma = CommaSelection.new(function()
  chooser = {}
  function chooser:show(choices, callback) self.choices, self.callback = choices, callback end
  function chooser:selectedRow(index) self.row = index end
  function chooser:select(index) self.callback(self.choices[index]) end
  return chooser
end)
local gate = RequestGate.new()
local selections = {}
local groups = ApplicationGroups.new({
  applications = {
    {id = "chat", name = "Google Chat", bundleID = "chat.app"},
    {id = "meet", name = "Google Meet", bundleID = "meet.app"},
  },
  commaSelection = comma,
  gate = gate,
  orchestrator = {capture = function(_, mode, generation)
    return {mode = mode, generation = generation, screen = "display"}
  end},
  navigation = {activate = function(_, application, mode, chooseInstance, request)
    selections[#selections + 1] = {application = application.id, mode = mode,
      chooseInstance = chooseInstance, request = request}
  end},
})
local group = {key = "i", applications = {"chat", "meet"}}
local release = function()
  taps[#taps].callback({getFlags = function() return {} end})
end

groups:cycle(group, 1, false, "focused")
assert(chooser.row == 1 and chooser.choices[1].text == "Google Chat")
assert(chooser.choices[2].image == "meet.app" and #selections == 0)
groups:cycle(group, 1, true, "other")
assert(chooser.row == 2 and gate:current() == 1)
release()
assert(selections[1].application == "meet" and selections[1].mode == "focused")
assert(selections[1].chooseInstance == false and selections[1].request.generation == 1)

groups:cycle(group, -1, true, "other")
assert(chooser.row == 2 and chooser.choices[2].text == "Google Meet")
release()
assert(selections[2].application == "meet" and selections[2].mode == "other")
assert(selections[2].chooseInstance == true and selections[2].request.generation == 2)

print("Hammerspoon application group tests passed")
