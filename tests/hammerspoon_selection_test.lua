-- Run from the repository root: lua tests/hammerspoon_selection_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local taps = {}
hs = {
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

local chooser
local function chooserFactory()
  chooser = {visible = false}
  function chooser:show(choices, callback) self.choices = choices; self.callback = callback; self.visible = true end
  function chooser:isVisible() return self.visible end
  function chooser:hide() self.visible = false end
  function chooser:selectedRow(row) self.row = row end
  function chooser:select(row) self.callback(self.choices[row]) end
  return chooser
end

local CommaSelection = require("modules.comma_selection")
local MediaControls = require("modules.media_controls")
local comma = CommaSelection.new(chooserFactory)
local selected
comma:cycle("windows", 1, {
  currentID = 1,
  load = function(done) done({{id = 1, text = "One"}, {id = 2, text = "Two"}}) end,
  onSelect = function(item) selected = item.id end,
})
assert(chooser.row == 2)
taps[#taps].callback({getFlags = function() return {} end})
assert(selected == 2 and comma.session == nil)

selected = nil
comma:cycle("windows", -1, {
  currentID = 1,
  load = function(done) done({{id = 1, text = "One"}, {id = 2, text = "Two"}}) end,
  onSelect = function(item) selected = item.id end,
})
assert(chooser.row == 2)
chooser.callback(nil)
assert(selected == nil and comma.session == nil)

local pending
comma:cycle("workspaces", 1, {
  load = function(done) pending = done end,
  onSelect = function(item) selected = item.id end,
})
comma:cycle("workspaces", 1, {})
pending({{id = "1", text = "One"}, {id = "2", text = "Two"}})
assert(chooser.row == 2)

comma:cancel()
local tasks = {}
local function taskNew(path, callback, arguments)
  local task = {path = path, callback = callback, arguments = arguments}
  function task:start() tasks[#tasks + 1] = self; return true end
  return task
end
local media = MediaControls.new({
  commaSelection = comma,
  taskNew = taskNew,
  notify = function() error("Media action unexpectedly failed") end,
})
media:cycle(1)
assert(chooser.row == 1 and chooser.choices[1].text == "Play/Pause")
taps[#taps].callback({getFlags = function() return {} end})
assert(tasks[1].path == "/usr/bin/osascript")
assert(tasks[1].arguments[2]:match("playpause$"))

media:cycle(1)
media:cycle(1)
assert(chooser.row == 2 and chooser.choices[2].text == "Next")
taps[#taps].callback({getFlags = function() return {} end})
assert(tasks[2].arguments[2]:match("next track$"))

media:cycle(-1)
assert(chooser.row == 3 and chooser.choices[3].text == "Previous")
taps[#taps].callback({getFlags = function() return {} end})
assert(tasks[3].arguments[2]:match("previous track$"))

print("Hammerspoon selection tests passed")
