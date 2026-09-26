-- Run from the repository root: lua tests/hammerspoon_layout_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local layout = require("modules.display_layout")

local screen = {x = -100, y = 24, w = 101, h = 80}
local full = layout.frame(screen, "full")
assert(full.x == -100 and full.y == 24)
assert(full.w == 101 and full.h == 80)

local left = layout.frame(screen, "left")
assert(left.x == -100 and left.y == 24)
assert(left.w == 50 and left.h == 80)

local right = layout.frame(screen, "right")
assert(right.x == -50 and right.y == 24)
assert(right.w == 51 and right.h == 80)

local ok, errorMessage = pcall(layout.frame, screen, "unknown")
assert(not ok and errorMessage:find("Unknown window position", 1, true))

print("Hammerspoon layout tests passed")
