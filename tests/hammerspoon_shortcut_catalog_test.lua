-- Run from the repository root: lua tests/hammerspoon_shortcut_catalog_test.lua
package.path = "home/.hammerspoon/?.lua;" .. package.path

local catalog = require("shortcut_catalog")

catalog.add("Media", "Media", "Media action")
catalog.add("Windows", "Window", "Window action")
catalog.add("Applications", "Application", "Application action")

local items = catalog.items()
assert(#items == 3)
assert(items[1].shortcut == "Application")
assert(items[2].shortcut == "Window")
assert(items[3].shortcut == "Media")

print("Hammerspoon shortcut catalog tests passed")
