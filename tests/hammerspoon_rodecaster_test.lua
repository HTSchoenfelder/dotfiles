-- Run from the repository root: lua tests/hammerspoon_rodecaster_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local DEVICE_NAME = "RODECaster Pro II"
local SETTINGS_KEY = "dotfiles.rodecaster.assumedMuted"

local now = 100
local availableDevices = {DEVICE_NAME}
local settings = {}
local devices = {}
local notices = {}
local deviceChangeCallback
local screenFrame = {x = 0, y = 0, w = 1200, h = 800}

local function copyFrame(frame)
  return {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
end

local function newDevice()
  local device = {online = true, commands = {}}

  function device:isOnline()
    return self.online
  end

  function device:callback(callback)
    self.commandCallback = callback
  end

  function device:sendCommand(commandType, metadata)
    self.commands[#self.commands + 1] = {
      commandType = commandType,
      metadata = metadata,
    }
    return true
  end

  devices[#devices + 1] = device
  return device
end

local function newCanvas(frame)
  local canvas = {currentFrame = copyFrame(frame), visible = false}

  function canvas:appendElements(...)
    self.elements = {...}
    return self
  end

  function canvas:level(level)
    self.currentLevel = level
    return self
  end

  function canvas:frame(nextFrame)
    if nextFrame then
      self.currentFrame = copyFrame(nextFrame)
      return self
    end
    return copyFrame(self.currentFrame)
  end

  function canvas:show()
    self.visible = true
    return self
  end

  function canvas:hide()
    self.visible = false
    return self
  end

  return canvas
end

local screenWatcher = {}
function screenWatcher:start()
  self.started = true
  return self
end

local runtime = {
  canvasLevel = "status",
  canvasNew = newCanvas,
  deviceCallback = function(callback)
    deviceChangeCallback = callback
  end,
  devices = function()
    return availableDevices
  end,
  log = function() end,
  newDevice = newDevice,
  notify = function(message)
    notices[#notices + 1] = message
  end,
  now = function()
    return now
  end,
  primaryScreen = function()
    return {frame = function() return copyFrame(screenFrame) end}
  end,
  screenWatcherNew = function(callback)
    screenWatcher.callback = callback
    return screenWatcher
  end,
  settingsGet = function(key)
    return settings[key]
  end,
  settingsSet = function(key, value)
    settings[key] = value
  end,
}

local Rodecaster = require("modules.rodecaster")
local rodecaster = Rodecaster.new({deviceName = DEVICE_NAME}, runtime):start()
rodecaster:start()

assert(#devices == 1, "start must be idempotent")
assert(deviceChangeCallback and screenWatcher.started)
assert(not rodecaster.assumedMuted)

assert(rodecaster:toggleMute())
assert(rodecaster.assumedMuted and settings[SETTINGS_KEY] == true)
assert(rodecaster.overlay.visible)
assert(#devices[1].commands == 1)
assert(devices[1].commands[1].metadata.controllerValue == 1)

now = 100.01
devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 1,
})
assert(rodecaster.assumedMuted, "outgoing mute echo must not toggle the state")

devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 0,
})
assert(rodecaster.assumedMuted, "button release must not change the state")

now = 100.02
assert(rodecaster:toggleMute())
assert(not rodecaster.assumedMuted)
assert(not rodecaster.overlay.visible)
assert(#devices[1].commands == 2)
assert(devices[1].commands[2].metadata.controllerValue == 0)

now = 101
devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 1,
})
assert(rodecaster.assumedMuted)

devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 1,
})
assert(rodecaster.assumedMuted, "duplicate button-down events must be ignored")

devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 0,
})
assert(rodecaster.assumedMuted)

now = 102
devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 1,
})
assert(not rodecaster.assumedMuted, "the next physical press must toggle the state")

devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 0,
})
assert(not rodecaster.assumedMuted)

now = 103
devices[1].commandCallback(nil, nil, "controlChange", nil, {
  channel = 0,
  controllerNumber = 27,
  controllerValue = 1,
})
assert(rodecaster.assumedMuted)

screenFrame.x = 1200
screenWatcher.callback()
assert(rodecaster.overlay.currentFrame.x == 1700)

availableDevices = {}
deviceChangeCallback(availableDevices)
assert(rodecaster.device == nil and not rodecaster.overlay.visible)
assert(not rodecaster:toggleMute())
assert(notices[#notices] == "MIDI device is not connected")

availableDevices = {DEVICE_NAME}
deviceChangeCallback(availableDevices)
assert(#devices == 2 and rodecaster.device == devices[2])
assert(rodecaster.overlay.visible, "persisted assumed state must survive reconnects")

devices[2].sendCommand = function()
  return false
end
assert(not rodecaster:toggleMute())
assert(rodecaster.device == nil and not rodecaster.overlay.visible)
assert(notices[#notices] == "Mute command failed")

local restored = Rodecaster.new({deviceName = DEVICE_NAME}, runtime)
assert(restored.assumedMuted, "assumed state must survive Hammerspoon reloads")

print("Hammerspoon RØDECaster tests passed")
