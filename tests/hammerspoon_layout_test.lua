-- Run from the repository root: lua tests/hammerspoon_layout_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local layout = require("modules.display_layout")

local full = layout.frames({x = -100, y = 24, w = 101, h = 80}, 1)
assert(#full == 1)
assert(full[1].x == -100 and full[1].y == 24)
assert(full[1].w == 101 and full[1].h == 80)

local split = layout.frames({x = -100, y = 24, w = 101, h = 80}, 2)
assert(#split == 2)
assert(split[1].x == -100 and split[1].w == 50)
assert(split[2].x == -50 and split[2].w == 51)
assert(split[1].h == 80 and split[2].h == 80)

assert(#layout.frames({x = 0, y = 0, w = 100, h = 100}, 0) == 0)

print("Hammerspoon layout tests passed")
