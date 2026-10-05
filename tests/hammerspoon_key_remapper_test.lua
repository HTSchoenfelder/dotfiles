-- Run from the repository root: lua tests/hammerspoon_key_remapper_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local KeyRemapper = require("modules.key_remapper")

local sent = {}
local createdTaps = {}
local frontmostBundleID = "com.google.Chrome"
local focusedElement

local function axElement(attributes, parent)
  return {
    attributeValue = function(_, name)
      if name == "AXParent" then
        return parent
      end
      return attributes[name]
    end,
  }
end

local function newTap(_, callback)
  local tap = {callback = callback}
  function tap:start()
    self.started = true
    return self
  end
  function tap:stop()
    self.started = false
  end
  table.insert(createdTaps, tap)
  return tap
end

local remapper = KeyRemapper.new({
  chromeBundleID = "com.google.Chrome",
  vsCodeBundleID = "com.microsoft.VSCode",
  terminalBundleIDs = {"net.kovidgoyal.kitty"},
}, {
  eventtapNew = newTap,
  frontmostApplication = function()
    return {bundleID = function() return frontmostBundleID end}
  end,
  focusedUIElement = function() return focusedElement end,
  keyDownType = "keyDown",
  keyName = function(keyCode) return keyCode end,
  send = function(mods, key)
    table.insert(sent, {mods = mods, key = key})
  end,
})

local function assertModifiers(actual, expected)
  assert(#actual == #expected, "unexpected modifier count")
  for index, modifier in ipairs(expected) do
    assert(actual[index] == modifier, "unexpected modifier at index " .. index)
  end
end

local function assertTarget(bundleID, key, flags, expectedMods, expectedKey, context)
  local target = remapper:translate(bundleID, key, flags, context)
  assert(target, "expected a target for " .. bundleID .. " " .. key)
  assert(target.key == expectedKey, "unexpected target key for " .. key)
  assertModifiers(target.mods, expectedMods)
end

local function assertIgnored(bundleID, key, flags)
  assert(remapper:translate(bundleID, key, flags) == nil, "expected shortcut to pass through")
end

local gui = "com.apple.TextEdit"
local chrome = "com.google.Chrome"
local terminal = "net.kovidgoyal.kitty"
local vscode = "com.microsoft.VSCode"

assertTarget(gui, "c", {ctrl = true}, {"cmd"}, "c")
assertTarget(gui, "z", {ctrl = true, shift = true}, {"cmd", "shift"}, "z")
assertTarget(gui, "y", {ctrl = true}, {"cmd", "shift"}, "z")
assertTarget(gui, "left", {ctrl = true}, {"alt"}, "left")
assertTarget(gui, "right", {ctrl = true, shift = true}, {"alt", "shift"}, "right")
assertTarget(gui, "delete", {ctrl = true}, {"alt"}, "delete")
assertTarget(gui, "forwarddelete", {ctrl = true}, {"alt"}, "forwarddelete")
assertTarget(gui, "home", {}, {"cmd"}, "left")
assertTarget(gui, "end", {shift = true}, {"cmd", "shift"}, "right")
assertTarget(gui, "home", {ctrl = true}, {"cmd"}, "up")
assertTarget(gui, "end", {ctrl = true, shift = true}, {"cmd", "shift"}, "down")
assertIgnored(gui, "c", {ctrl = true, cmd = true})

assertIgnored(terminal, "left", {ctrl = true})
assertTarget(terminal, "c", {ctrl = true, shift = true}, {"cmd"}, "c")
assertTarget(terminal, "v", {ctrl = true, shift = true}, {"cmd"}, "v")
assertTarget(terminal, "z", {ctrl = true, shift = true}, {"cmd", "shift"}, "z")
assertIgnored(vscode, "c", {ctrl = true})

local codexInput = axElement({
  AXRole = "AXTextArea",
  AXDescription = "Ask for follow-up changes",
})
local searchInput = axElement({
  AXRole = "AXTextField",
  AXDescription = "Search",
})
local codeGroup = axElement({AXRole = "AXGroup", AXSubrole = "AXCodeStyleGroup"})
local editorInput = axElement({AXRole = "AXTextArea"}, codeGroup)
local terminalInput = axElement({
  AXRole = "AXTextField",
  AXDescription = "Terminal 1, zsh Use Option+F1 for terminal accessibility help",
})

assert(remapper:_isVSCodeTextInput(codexInput))
assert(remapper:_isVSCodeTextInput(searchInput))
assert(not remapper:_isVSCodeTextInput(editorInput))
assert(not remapper:_isVSCodeTextInput(terminalInput))
assertTarget(vscode, "left", {ctrl = true}, {"alt"}, "left", {vsCodeTextInput = true})
assertIgnored(vscode, "left", {ctrl = true})

assertTarget(chrome, "p", {ctrl = true}, {"cmd", "shift"}, "a")
assertTarget(chrome, "h", {ctrl = true}, {"cmd"}, "left")
assertTarget(chrome, "j", {ctrl = true}, {"ctrl", "shift"}, "tab")
assertTarget(chrome, "k", {ctrl = true}, {"ctrl"}, "tab")
assertTarget(chrome, "l", {ctrl = true}, {"cmd"}, "right")
assertTarget(chrome, "t", {ctrl = true}, {"cmd"}, "t")
assertTarget(chrome, "t", {ctrl = true, shift = true}, {"cmd", "shift"}, "t")
assertTarget(chrome, "r", {ctrl = true}, {"cmd"}, "r")
assertTarget(chrome, "r", {ctrl = true, shift = true}, {"cmd", "shift"}, "r")
assertTarget(chrome, "n", {ctrl = true}, {"cmd"}, "n")
assertTarget(chrome, "n", {ctrl = true, shift = true}, {"cmd", "shift"}, "n")
assertTarget(chrome, "o", {ctrl = true}, {"cmd"}, "o")
assertTarget(chrome, "d", {ctrl = true}, {"cmd"}, "d")
assertTarget(chrome, "d", {ctrl = true, shift = true}, {"cmd", "shift"}, "d")
assertTarget(chrome, "1", {ctrl = true}, {"cmd"}, "1")
assertTarget(chrome, "0", {ctrl = true}, {"cmd"}, "0")
assertTarget(chrome, "b", {ctrl = true, shift = true}, {"cmd", "shift"}, "b")
assertTarget(chrome, "delete", {ctrl = true, shift = true}, {"cmd", "shift"}, "delete")
assertTarget(chrome, "w", {ctrl = true, shift = true}, {"cmd", "shift"}, "w")
assertTarget(chrome, "c", {ctrl = true}, {"cmd"}, "c")

remapper:start()
remapper:start()
assert(#createdTaps == 1 and createdTaps[1].started, "start must be idempotent")

local event = {
  getFlags = function() return {ctrl = true} end,
  getKeyCode = function() return "p" end,
}
assert(createdTaps[1].callback(event))
assert(#sent == 1)
assert(sent[1].key == "a")
assertModifiers(sent[1].mods, {"cmd", "shift"})

frontmostBundleID = vscode
focusedElement = codexInput
local wordLeftEvent = {
  getFlags = function() return {ctrl = true} end,
  getKeyCode = function() return "left" end,
}
assert(createdTaps[1].callback(wordLeftEvent))
assert(#sent == 2 and sent[2].key == "left")
assertModifiers(sent[2].mods, {"alt"})

focusedElement = editorInput
assert(not createdTaps[1].callback(wordLeftEvent))
assert(#sent == 2, "Monaco editor navigation must remain application-owned")

focusedElement = terminalInput
assert(not createdTaps[1].callback(wordLeftEvent))
assert(#sent == 2, "terminal navigation must remain shell-owned")

remapper:stop()
assert(not createdTaps[1].started and remapper.tap == nil)

print("Hammerspoon key remapper tests passed")
