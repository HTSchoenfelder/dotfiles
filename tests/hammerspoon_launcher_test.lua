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

print("Hammerspoon launcher tests passed")
