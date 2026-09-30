-- Run from the repository root: lua tests/hammerspoon_chooser_test.lua
package.path = "home/.hammerspoon/?.lua;" .. package.path

local nativeChoices
local nativeCallback
local instance = {}
function instance:rows() return self end
function instance:width() return self end
function instance:searchSubText() return self end
function instance:placeholderText() return self end
function instance:bgDark(value) self.dark = value; return self end
function instance:fgColor(value) self.foreground = value; return self end
function instance:subTextColor(value) self.secondary = value; return self end
function instance:choices(choices) nativeChoices = choices; return self end
function instance:query() return self end
function instance:show() return self end

hs = {
  chooser = {
    new = function(callback)
      nativeCallback = callback
      return instance
    end,
  },
  window = {focusedWindow = function() return nil end},
  screen = {mainScreen = function() return nil end},
}

local Chooser = require("modules.chooser")
local chooser = Chooser.new({
  dark = true,
  foregroundColor = {name = "foreground"},
  secondaryColor = {name = "secondary"},
  showWindowTitles = false,
})
local windowObject = {native = true}
local original = {{
  text = "Code",
  subText = "dotfiles",
  kind = "window",
  record = {window = windowObject},
}}
local selected
chooser:show(original, function(choice) selected = choice end)

assert(nativeChoices[1].text == "Code" and nativeChoices[1].subText == nil)
assert(nativeChoices[1].record == nil)
assert(nativeChoices[1].uuid == "1")
assert(instance.dark and instance.foreground.name == "foreground")
assert(instance.secondary.name == "secondary")
nativeCallback(nativeChoices[1])
assert(selected == original[1] and selected.record.window == windowObject)

print("Hammerspoon chooser tests passed")
