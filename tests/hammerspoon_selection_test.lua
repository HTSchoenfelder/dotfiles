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
local RequestGate = require("modules.request_gate")
local WindowNavigation = require("modules.window_navigation")
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
local mediaActions = {}
local media = MediaControls.new({
  commaSelection = comma,
  openSpotify = function() mediaActions[#mediaActions + 1] = "spotify" end,
  sendMediaKey = function(key) mediaActions[#mediaActions + 1] = key end,
})
media:cycle(1)
assert(chooser.row == 1 and chooser.choices[1].text == "Play/Pause")
taps[#taps].callback({getFlags = function() return {} end})
assert(mediaActions[1] == "PLAY")

media:cycle(1)
media:cycle(1)
assert(chooser.row == 2 and chooser.choices[2].text == "Next")
taps[#taps].callback({getFlags = function() return {} end})
assert(mediaActions[2] == "NEXT")

media:cycle(1)
media:cycle(1)
media:cycle(1)
assert(chooser.row == 3)
taps[#taps].callback({getFlags = function() return {} end})
assert(mediaActions[3] == "PREVIOUS")

media:cycle(-1)
assert(chooser.row == 4 and chooser.choices[4].text == "Spotify")
taps[#taps].callback({getFlags = function() return {} end})
assert(mediaActions[4] == "spotify")

media:cycle(1)
chooser.callback(nil)
assert(#mediaActions == 4, "cancel must not send a media key")

local systemEvents = {}
hs.eventtap.event.newSystemKeyEvent = function(key, down)
  return {post = function() systemEvents[#systemEvents + 1] = {key = key, down = down} end}
end
local nativeMedia = MediaControls.new({commaSelection = comma, openSpotify = function() end})
for index = 1, 3 do
  nativeMedia:execute(MediaControls.actions[index])
  assert(systemEvents[index * 2 - 1].key == MediaControls.actions[index].mediaKey)
  assert(systemEvents[index * 2 - 1].down and not systemEvents[index * 2].down)
end

local activeScreen = "first"
local actions = {}
local layoutGate = RequestGate.new()
local layoutNavigation = WindowNavigation.new({
  gate = layoutGate,
  orchestrator = {
    activeScreen = function() return activeScreen end,
    keepOnly = function(_, screen) actions[#actions + 1] = {"single", screen} end,
    enableTwo = function(_, screen, ratio)
      actions[#actions + 1] = {"split", screen, ratio}
    end,
  },
})
local function releaseLayout()
  taps[#taps].callback({getFlags = function() return {} end})
end

layoutNavigation:cycleLayout(comma)
assert(chooser.row == 1 and chooser.choices[1].text == "One slot, full screen")
assert(chooser.choices[2].text == "Two slots, 50:50")
assert(chooser.choices[3].text == "Two slots, 70:30")
assert(#actions == 0)
activeScreen = "second"
releaseLayout()
assert(actions[1][1] == "single" and actions[1][2] == "first")

layoutNavigation:cycleLayout(comma)
layoutNavigation:cycleLayout(comma)
assert(chooser.row == 2 and #actions == 1)
releaseLayout()
assert(actions[2][1] == "split" and actions[2][2] == "second"
  and actions[2][3] == 0.5)

layoutNavigation:cycleLayout(comma)
layoutNavigation:cycleLayout(comma)
layoutNavigation:cycleLayout(comma)
assert(chooser.row == 3 and #actions == 2)
releaseLayout()
assert(actions[3][1] == "split" and actions[3][2] == "second"
  and actions[3][3] == 0.7)

print("Hammerspoon selection tests passed")
