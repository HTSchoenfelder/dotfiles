local KeyRemapper = {}
KeyRemapper.__index = KeyRemapper

local generalCommandKeys = {
  a = true,
  c = true,
  f = true,
  s = true,
  v = true,
  w = true,
  x = true,
  z = true,
}

local chromeCustomKeys = {
  h = {mods = {"cmd"}, key = "left"},
  j = {mods = {"ctrl", "shift"}, key = "tab"},
  k = {mods = {"ctrl"}, key = "tab"},
  l = {mods = {"cmd"}, key = "right"},
  p = {mods = {"cmd", "shift"}, key = "a"},
}

local chromeCommandKeys = {
  ["0"] = true,
  ["1"] = true,
  ["2"] = true,
  ["3"] = true,
  ["4"] = true,
  ["5"] = true,
  ["6"] = true,
  ["7"] = true,
  ["8"] = true,
  ["9"] = true,
  ["-"] = true,
  ["="] = true,
  d = true,
  n = true,
  o = true,
  r = true,
  t = true,
}

local chromeShiftCommandKeys = {
  ["="] = true,
  b = true,
  d = true,
  delete = true,
  n = true,
  r = true,
  t = true,
}

local function toSet(values)
  local result = {}
  for _, value in ipairs(values or {}) do
    result[value] = true
  end
  return result
end

local function modifiers(base, shifted)
  local result = {}
  for _, modifier in ipairs(base) do
    table.insert(result, modifier)
  end
  if shifted then
    table.insert(result, "shift")
  end
  return result
end

function KeyRemapper.new(options, runtime)
  options = options or {}
  runtime = runtime or {}

  return setmetatable({
    chromeBundleID = options.chromeBundleID or "com.google.Chrome",
    terminalApps = toSet(options.terminalBundleIDs),
    vsCodeBundleID = options.vsCodeBundleID or "com.microsoft.VSCode",
    eventtapNew = runtime.eventtapNew or function(types, callback)
      return hs.eventtap.new(types, callback)
    end,
    frontmostApplication = runtime.frontmostApplication or function()
      return hs.application.frontmostApplication()
    end,
    keyDownType = runtime.keyDownType or hs.eventtap.event.types.keyDown,
    keyName = runtime.keyName or function(keyCode)
      return hs.keycodes.map[keyCode]
    end,
    send = runtime.send or function(mods, key)
      hs.eventtap.keyStroke(mods, key, 0)
    end,
  }, KeyRemapper)
end

function KeyRemapper:_terminalTranslation(key, flags)
  if not (flags.ctrl and flags.shift) or flags.cmd or flags.alt then
    return nil
  end

  if key == "c" or key == "v" then
    return {mods = {"cmd"}, key = key}
  end
  if key == "z" then
    return {mods = {"cmd", "shift"}, key = "z"}
  end

  return nil
end

function KeyRemapper:_chromeTranslation(key, flags)
  if not flags.ctrl or flags.cmd or flags.alt then
    return nil
  end

  if not flags.shift and chromeCustomKeys[key] then
    return chromeCustomKeys[key]
  end

  local commandKeys = flags.shift and chromeShiftCommandKeys or chromeCommandKeys
  if commandKeys[key] then
    return {mods = modifiers({"cmd"}, flags.shift), key = key}
  end

  return nil
end

function KeyRemapper:_textTranslation(key, flags)
  if flags.cmd or flags.alt then
    return nil
  end

  if flags.ctrl then
    if key == "left" or key == "right" then
      return {mods = modifiers({"alt"}, flags.shift), key = key}
    end
    if key == "delete" or key == "forwarddelete" then
      return {mods = {"alt"}, key = key}
    end
    if key == "home" or key == "end" then
      local targetKey = key == "home" and "up" or "down"
      return {mods = modifiers({"cmd"}, flags.shift), key = targetKey}
    end
  elseif key == "home" or key == "end" then
    local targetKey = key == "home" and "left" or "right"
    return {mods = modifiers({"cmd"}, flags.shift), key = targetKey}
  end

  return nil
end

function KeyRemapper:_editingTranslation(key, flags)
  if not flags.ctrl or flags.cmd or flags.alt then
    return nil
  end

  if key == "y" then
    return {mods = {"cmd", "shift"}, key = "z"}
  end
  if generalCommandKeys[key] then
    return {mods = modifiers({"cmd"}, flags.shift), key = key}
  end

  return nil
end

function KeyRemapper:translate(bundleID, key, flags)
  if not bundleID or not key then
    return nil
  end

  flags = flags or {}

  if self.terminalApps[bundleID] then
    return self:_terminalTranslation(key, flags)
  end
  if bundleID == self.vsCodeBundleID then
    return nil
  end
  if bundleID == self.chromeBundleID then
    local chromeTarget = self:_chromeTranslation(key, flags)
    if chromeTarget then
      return chromeTarget
    end
  end

  return self:_textTranslation(key, flags) or self:_editingTranslation(key, flags)
end

function KeyRemapper:_handle(event)
  local application = self.frontmostApplication()
  if not application then
    return false
  end

  local target = self:translate(
    application:bundleID(),
    self.keyName(event:getKeyCode()),
    event:getFlags()
  )
  if not target then
    return false
  end

  self.send(target.mods, target.key)
  return true
end

function KeyRemapper:start()
  if self.tap then
    return self
  end

  self.tap = self.eventtapNew({self.keyDownType}, function(event)
    return self:_handle(event)
  end)
  self.tap:start()
  return self
end

function KeyRemapper:stop()
  if not self.tap then
    return
  end

  self.tap:stop()
  self.tap = nil
end

return KeyRemapper
