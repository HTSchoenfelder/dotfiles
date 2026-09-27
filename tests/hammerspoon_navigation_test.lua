-- Run from the repository root: lua tests/hammerspoon_navigation_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local screen = {
  frame = function() return {x = 0, y = 20, w = 1200, h = 800} end,
  getUUID = function() return "screen-1" end,
}

local function application(pid, name)
  return {
    pid = function() return pid end,
    name = function() return name end,
    isHidden = function() return false end,
  }
end

local function window(id, owner, title)
  return {
    id = function() return id end,
    application = function() return owner end,
    title = function() return title end,
    isStandard = function() return true end,
    isFullScreen = function() return false end,
    isMinimized = function() return false end,
    screen = function() return screen end,
    setFrame = function(self, frame) self.placed = frame end,
    focus = function(self) self.focused = true end,
  }
end

local focused
local choosers = {}
local keyStroke
hs = {
  window = {
    focusedWindow = function() return focused end,
    orderedWindows = function() return {} end,
    allWindows = function() return {} end,
  },
  screen = {
    mainScreen = function() return screen end,
    primaryScreen = function() return screen end,
    allScreens = function() return {screen} end,
  },
  timer = {
    doAfter = function(_, callback) callback() end,
  },
  chooser = {
    new = function(callback)
      local chooser = {callback = callback}
      function chooser:rows() return self end
      function chooser:searchSubText() return self end
      function chooser:placeholderText() return self end
      function chooser:choices(choices) self.items = choices; return self end
      function chooser:query() return self end
      function chooser:show() self.visible = true; return self end
      function chooser:selectedRow(row) self.row = row; return self end
      function chooser:select(row) self.callback(self.items[row]); return self end
      choosers[#choosers + 1] = chooser
      return chooser
    end,
  },
  eventtap = {
    event = {types = {flagsChanged = 1}},
    new = function(_, callback)
      local tap = {callback = callback}
      function tap:start() self.running = true; return self end
      function tap:stop() self.running = false; return self end
      return tap
    end,
    keyStroke = function(modifiers, key, delay, owner)
      keyStroke = {modifiers = modifiers, key = key, delay = delay, owner = owner}
    end,
  },
}

local WindowNavigation = require("modules.window_navigation")
local navigation = WindowNavigation.new({restoreDelaySeconds = 0})
local firstApp = application(1, "First")
local secondApp = application(2, "Second")
local anchor = window(1, firstApp, "Anchor")
local target = window(2, secondApp, "Target")
focused = anchor

navigation:activate(target, {mode = "stack", screen = screen, anchor = anchor})
assert(anchor.placed.x == 0 and anchor.placed.w == 600)
assert(target.placed.x == 600 and target.placed.w == 600 and target.focused)

target.focused = false
navigation:activate(target, {mode = "single", screen = screen})
assert(target.placed.x == 0 and target.placed.w == 1200 and target.focused)

local activated
local chooserNavigation = {
  allWindows = function() return {anchor, target} end,
  activate = function(_, selected, request) activated = {window = selected, request = request} end,
}
local CommaSelection = require("modules.comma_selection")
local comma = CommaSelection.new(chooserNavigation, {rows = 7})
local request = {mode = "stack", anchor = anchor, screen = screen}
comma:cycle(1, false, request)
assert(choosers[#choosers].visible and choosers[#choosers].row == 2)
comma.session.releaseTap.callback({getFlags = function() return {} end})
assert(activated.window == target and activated.request == request)

activated = nil
focused = anchor
comma:cycle(1, true, request)
assert(choosers[#choosers].row == 1)
comma.session.releaseTap.callback({getFlags = function() return {} end})
assert(activated.window == anchor)

local ApplicationNavigation = require("modules.application_navigation")
local appNavigation = ApplicationNavigation.new({}, {}, chooserNavigation)
appNavigation:requestNewWindow({
  newWindowShortcut = {modifiers = {"cmd", "shift"}, key = "n"},
}, secondApp)
assert(keyStroke.key == "n" and keyStroke.owner == secondApp)
assert(keyStroke.modifiers[1] == "cmd" and keyStroke.modifiers[2] == "shift")

print("Hammerspoon navigation tests passed")
