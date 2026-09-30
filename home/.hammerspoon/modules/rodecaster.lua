local Rodecaster = {}
Rodecaster.__index = Rodecaster

local function contains(values, target)
  for _, value in ipairs(values or {}) do
    if value == target then
      return true
    end
  end
  return false
end

function Rodecaster.new(options, runtime)
  options = options or {}
  runtime = runtime or {}
  local overlay = options.overlay or {}

  local rodecaster = setmetatable({
    deviceName = options.deviceName or "RODECaster Pro II",
    channel = options.channel or 0,
    controllerNumber = options.controllerNumber or 27,
    pressValue = options.pressValue or 1,
    releaseValue = options.releaseValue or 0,
    releaseDelay = options.releaseDelaySeconds or 0.1,
    incomingDebounce = options.incomingDebounceSeconds or 0.3,
    echoSuppression = options.echoSuppressionSeconds or 0.3,
    settingsKey = options.settingsKey or "dotfiles.rodecaster.assumedMuted",
    overlayWidth = overlay.width or 200,
    overlayHeight = overlay.height or 50,
    overlayBottomMargin = overlay.bottomMargin or 80,
    overlayRadius = overlay.radius or 10,
    overlayTextSize = overlay.textSize or 22,
    overlayFillColor = overlay.fillColor or {hex = "#f38ba8", alpha = 0.9},
    overlayTextColor = overlay.textColor or {hex = "#1e1e2e"},
    device = nil,
    lastIncomingAt = -math.huge,
    suppressIncomingUntil = -math.huge,
    started = false,
    after = runtime.after or function(delay, callback)
      hs.timer.doAfter(delay, callback)
    end,
    canvasLevel = runtime.canvasLevel or hs.canvas.windowLevels.status,
    canvasNew = runtime.canvasNew or function(frame)
      return hs.canvas.new(frame)
    end,
    deviceCallback = runtime.deviceCallback or function(callback)
      hs.midi.deviceCallback(callback)
    end,
    devices = runtime.devices or function()
      return hs.midi.devices()
    end,
    log = runtime.log or function(message)
      hs.printf("%s", message)
    end,
    newDevice = runtime.newDevice or function(name)
      return hs.midi.new(name)
    end,
    notify = runtime.notify or function(message)
      hs.notify.new({title = "RØDECaster", informativeText = message}):send()
    end,
    now = runtime.now or function()
      return hs.timer.absoluteTime() / 1000000000
    end,
    primaryScreen = runtime.primaryScreen or function()
      return hs.screen.primaryScreen()
    end,
    screenWatcherNew = runtime.screenWatcherNew or function(callback)
      return hs.screen.watcher.new(callback)
    end,
    settingsGet = runtime.settingsGet or function(key)
      return hs.settings.get(key)
    end,
    settingsSet = runtime.settingsSet or function(key, value)
      return hs.settings.set(key, value)
    end,
  }, Rodecaster)

  rodecaster.assumedMuted = rodecaster.settingsGet(rodecaster.settingsKey) == true
  return rodecaster
end

function Rodecaster:_isOnline(device)
  if not device or type(device.isOnline) ~= "function" then
    return false
  end

  local ok, online = pcall(device.isOnline, device)
  return ok and online == true
end

function Rodecaster:_overlayFrame()
  local screen = self.primaryScreen()
  if not screen then
    return nil
  end

  local frame = screen:frame()
  return {
    x = frame.x + (frame.w - self.overlayWidth) / 2,
    y = frame.y + frame.h - self.overlayHeight - self.overlayBottomMargin,
    w = self.overlayWidth,
    h = self.overlayHeight,
  }
end

function Rodecaster:_getOverlay()
  if self.overlay then
    return self.overlay
  end

  local frame = self:_overlayFrame()
  if not frame then
    return nil
  end

  self.overlay = self.canvasNew(frame)
  self.overlay:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = self.overlayFillColor,
    roundedRectRadii = {xRadius = self.overlayRadius, yRadius = self.overlayRadius},
  }, {
    type = "text",
    text = "🎙️ MUTED",
    textColor = self.overlayTextColor,
    textSize = self.overlayTextSize,
    textAlignment = "center",
    frame = {x = "0%", y = "15%", w = "100%", h = "100%"},
  })
  self.overlay:level(self.canvasLevel)
  return self.overlay
end

function Rodecaster:_positionOverlay()
  if not self.overlay then
    return
  end

  local frame = self:_overlayFrame()
  if frame then
    self.overlay:frame(frame)
  end
end

function Rodecaster:_syncOverlay()
  if self.assumedMuted and self:_isOnline(self.device) then
    local overlay = self:_getOverlay()
    if overlay then
      self:_positionOverlay()
      overlay:show()
    end
  elseif self.overlay then
    self.overlay:hide()
  end
end

function Rodecaster:_setAssumedMuted(muted)
  self.assumedMuted = muted == true
  self.settingsSet(self.settingsKey, self.assumedMuted)
  self:_syncOverlay()
  self.log(string.format("RØDECaster assumed mute state: %s", tostring(self.assumedMuted)))
end

function Rodecaster:_toggleAssumedMute()
  self:_setAssumedMuted(not self.assumedMuted)
end

function Rodecaster:_isMutePress(commandType, metadata)
  return commandType == "controlChange"
    and type(metadata) == "table"
    and metadata.channel == self.channel
    and metadata.controllerNumber == self.controllerNumber
    and metadata.controllerValue == self.pressValue
end

function Rodecaster:_handleCommand(commandType, metadata)
  if not self:_isMutePress(commandType, metadata) then
    return
  end

  local now = self.now()
  if now <= self.suppressIncomingUntil then
    return
  end
  if now - self.lastIncomingAt <= self.incomingDebounce then
    return
  end

  self.lastIncomingAt = now
  self:_toggleAssumedMute()
end

function Rodecaster:_connect(devices)
  if not contains(devices or self.devices(), self.deviceName) then
    local wasConnected = self.device ~= nil
    self.device = nil
    self:_syncOverlay()
    if wasConnected then
      self.log("RØDECaster MIDI device disconnected")
    end
    return false
  end

  if self:_isOnline(self.device) then
    return true
  end

  self.device = self.newDevice(self.deviceName)
  if not self.device then
    self.log("RØDECaster MIDI device could not be opened")
    return false
  end

  self.device:callback(function(_, _, commandType, _, metadata)
    self:_handleCommand(commandType, metadata)
  end)
  self:_syncOverlay()
  self.log("RØDECaster MIDI listener ready")
  return true
end

function Rodecaster:start()
  if self.started then
    return self
  end

  self.started = true
  self:_connect()
  self.deviceCallback(function(devices)
    self:_connect(devices)
  end)
  self.screenWatcher = self.screenWatcherNew(function()
    self:_positionOverlay()
  end):start()
  return self
end

function Rodecaster:_send(device, value)
  local ok, sentOrError = pcall(device.sendCommand, device, "controlChange", {
    channel = self.channel,
    controllerNumber = self.controllerNumber,
    controllerValue = value,
  })
  if not ok or sentOrError ~= true then
    local detail = ok and "device rejected command" or tostring(sentOrError)
    self.log("RØDECaster MIDI send failed: " .. detail)
    return false
  end
  return true
end

function Rodecaster:toggleMute()
  if not self:_isOnline(self.device) then
    self:_connect()
  end

  local device = self.device
  if not device then
    self.notify("MIDI device is not connected")
    return false
  end

  self.suppressIncomingUntil = self.now() + self.echoSuppression
  if not self:_send(device, self.pressValue) then
    self.device = nil
    self:_syncOverlay()
    self.notify("Mute command failed")
    return false
  end

  self.after(self.releaseDelay, function()
    if self:_isOnline(device) then
      self:_send(device, self.releaseValue)
    end
  end)
  self:_toggleAssumedMute()
  return true
end

return Rodecaster
