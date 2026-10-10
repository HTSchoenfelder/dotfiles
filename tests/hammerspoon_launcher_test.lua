-- Run from the repository root: lua tests/hammerspoon_launcher_test.lua
package.path = "home/.hammerspoon/?.lua;" .. package.path

local iconBundleID
hs = {
  application = {
    infoForBundlePath = function(path)
      if path == "/Applications/Visible.app" then
        return {CFBundleIdentifier = "example.visible", CFBundleDisplayName = "Visible"}
      end
      return {CFBundleIdentifier = "example.helper", CFBundleDisplayName = "Helper"}
    end,
  },
  image = {
    imageFromAppBundle = function(bundleID)
      iconBundleID = bundleID
      return "icon"
    end,
    iconForFile = function() return "file-icon" end,
  },
}

local Launcher = require("launcher")
local launcher = Launcher.new({})
local choices = launcher:_choices(table.concat({
  "/Applications/Visible.app",
  "/Applications/Visible.app/Contents/Helpers/Helper.app",
  "/System/Library/PrivateFrameworks/Example.framework/Helper.app",
}, "\n"))

assert(#choices == 1 and choices[1].text == "Visible")
assert(choices[1].image == "icon" and iconBundleID == "example.visible")

local RequestGate = require("modules.request_gate")
local gate = RequestGate.new()
local placed
hs.task = {new = function(_, callback)
  return {start = function()
    callback(0, "/Applications/Visible.app", "")
    return true
  end}
end}
hs.application.launchOrFocus = function() error("Existing app should fill the captured slot") end
local activeLauncher = Launcher.new({
  gate = gate,
  orchestrator = {
    capture = function(_, mode, generation)
      return {mode = mode, generation = generation, screenKey = "other"}
    end,
    activate = function(_, record, request) placed = {record = record, request = request} end,
  },
  repository = {listForBundle = function(_, _, callback)
    callback({{id = 8, title = "Window", window = {}}})
  end},
  chooserFactory = function()
    return {show = function(_, items, callback) callback(items[1]) end}
  end,
})
activeLauncher:toggle()
assert(placed.record.id == 8 and placed.request.screenKey == "other")

print("Hammerspoon launcher tests passed")
