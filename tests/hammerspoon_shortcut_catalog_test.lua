-- Run from the repository root: lua tests/hammerspoon_shortcut_catalog_test.lua
package.path = "home/.hammerspoon/?.lua;" .. package.path

local catalog = require("shortcut_catalog")

catalog.add("Media", "Media", "Media action")
local runs = 0
catalog.add("Windows", "Window", "Window action", function() runs = runs + 1 end)
catalog.add("Applications", "Application", "Application action")

local items = catalog.items()
assert(#items == 3)
assert(items[1].shortcut == "Application")
assert(items[2].shortcut == "Window")
assert(items[3].shortcut == "Media")

local choices, selectChoice, pending
catalog.chooserFactory = function()
  return {
    show = function(_, shown, callback)
      choices, selectChoice = shown, callback
    end,
  }
end
hs = {timer = {doAfter = function(_, callback) pending = callback end}}
catalog.show()
assert(choices[2].text == "Window" and type(choices[2].action) == "function")
selectChoice(choices[2])
assert(runs == 0 and type(pending) == "function")
pending()
assert(runs == 1)
pending = nil
catalog.show()
selectChoice(nil)
assert(pending == nil and runs == 1)

local bindings = {}
hs.hotkey = {bind = function(modifiers, key, action)
  assert(table.concat(modifiers, "+") == "alt+ctrl+cmd+shift")
  bindings[key] = action
  return {key = key}
end}
catalog.start({"alt", "ctrl", "cmd"}, catalog.chooserFactory)
assert(bindings.p == catalog.show and bindings.r == nil)
bindings.p()
assert(#choices == 4)
for _, choice in ipairs(choices) do
  assert(choice.text ~= "MainMod + Shift + R")
end

print("Hammerspoon shortcut catalog tests passed")
