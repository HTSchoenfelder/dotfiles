-- Run from the repository root: lua tests/hammerspoon_clipboard_history_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local current = { ["public.utf8-plain-text"] = "first" }
local text = "first"
local frontmost = {bundleID = function() return "com.example.Editor" end}
local watcherCallback
local choices
local selectedCallback
local pasted
local written
local origin = {focus = function() end, screen = function() return "screen" end}

local ClipboardHistory = require("modules.clipboard_history")
local history = ClipboardHistory.new({
  chooserFactory = function()
    return {show = function(_, items, callback, screen)
      choices, selectedCallback = items, callback
      assert(screen == "screen")
    end}
  end,
  maxEntries = 2,
  excludedBundleIDs = { ["org.keepassxc.keepassxc"] = true },
  runtime = {
    frontmostApplication = function() return frontmost end,
    focusedWindow = function() return origin end,
    keyStroke = function(modifiers, key) pasted = modifiers[1] .. "+" .. key end,
    readAllData = function() return current end,
    readImage = function() return nil end,
    readString = function() return text end,
    writeAllData = function(data) written = data end,
    watcherNew = function(callback) watcherCallback = callback; return {} end,
    doAfter = function(_, callback) callback() end,
  },
}):start()

current, text = {["public.utf8-plain-text"] = "second"}, "second"
watcherCallback()
current, text = {["public.utf8-plain-text"] = "first"}, "first"
watcherCallback()
assert(#history.entries == 2 and history.entries[1].label == "first" and history.entries[2].label == "second")

frontmost = {bundleID = function() return "org.keepassxc.keepassxc" end}
current, text = {["public.utf8-plain-text"] = "secret"}, "secret"
watcherCallback()
assert(#history.entries == 2 and history.entries[1].label == "first")

history:open()
assert(#choices == 2 and choices[2].text == "second")
selectedCallback(choices[2])
assert(written["public.utf8-plain-text"] == "second" and pasted == "cmd+v")

print("Hammerspoon clipboard history tests passed")
