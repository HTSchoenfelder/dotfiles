local midi = {
  deviceName = "RODECaster Pro II",
  device = nil,
  isMuted = false,
  lastToggleTime = 0,
}

local function contains(values, target)
  for _, value in ipairs(values or {}) do
    if value == target then return true end
  end
  return false
end

function midi:_overlay()
  if self.overlay then return self.overlay end
  local frame = hs.screen.primaryScreen():frame()
  local width, height = 200, 50
  self.overlay = hs.canvas.new({
    x = frame.x + (frame.w - width) / 2,
    y = frame.y + frame.h - height - 80,
    w = width,
    h = height,
  })
  self.overlay:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = {red = 0.9, green = 0.1, blue = 0.1, alpha = 0.85},
    roundedRectRadii = {xRadius = 10, yRadius = 10},
  }, {
    type = "text",
    text = "🎙️ MUTED",
    textColor = {white = 1, alpha = 1},
    textSize = 22,
    textAlignment = "center",
    frame = {x = "0%", y = "15%", w = "100%", h = "100%"},
  })
  self.overlay:level(hs.canvas.windowLevels.status)
  return self.overlay
end

function midi:_flipMuteState()
  local now = hs.timer.secondsSinceEpoch()
  if now - self.lastToggleTime <= 0.3 then return end
  self.isMuted = not self.isMuted
  self.lastToggleTime = now
  if self.isMuted then self:_overlay():show()
  elseif self.overlay then self.overlay:hide() end
  hs.printf("RØDECaster mute state: %s", tostring(self.isMuted))
end

function midi:_connect(devices)
  if not contains(devices or hs.midi.devices(), self.deviceName) then
    self.device = nil
    hs.printf("RØDECaster MIDI device is not connected")
    return
  end
  if self.device and self.device:isOnline() then return end
  self.device = hs.midi.new(self.deviceName)
  if not self.device then return end
  self.device:callback(function(_, _, commandType, _, metadata)
    if commandType == "controlChange" and metadata.channel == 0
        and metadata.controllerNumber == 27 and metadata.controllerValue == 1 then
      self:_flipMuteState()
    end
  end)
  hs.printf("RØDECaster MIDI listener ready")
end

function midi:start()
  self:_connect()
  hs.midi.deviceCallback(function(devices) self:_connect(devices) end)
end

function midi:toggleMute()
  if not self.device or not self.device:isOnline() then
    self:_connect()
  end
  if not self.device then
    hs.notify.new({title = "RØDECaster", informativeText = "MIDI device is not connected"}):send()
    return
  end
  self.device:sendCommand("controlChange", {
    channel = 0, controllerNumber = 27, controllerValue = 1,
  })
  hs.timer.doAfter(0.1, function()
    if self.device and self.device:isOnline() then
      self.device:sendCommand("controlChange", {
        channel = 0, controllerNumber = 27, controllerValue = 0,
      })
    end
  end)
  self:_flipMuteState()
end

return midi
