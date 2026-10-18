local ClipboardHistory = {}
ClipboardHistory.__index = ClipboardHistory

local function oneLine(value)
  value = value:gsub("[%c]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  local length = utf8.len(value)
  if length and length > 160 then
    return value:sub(1, utf8.offset(value, 158) - 1) .. "..."
  end
  return value
end

local function fingerprint(data)
  local parts = {}
  for kind, value in pairs(data or {}) do
    if type(value) == "string" then
      parts[#parts + 1] = kind .. ":" .. #value .. ":" .. value:sub(1, 64) .. value:sub(-64)
    end
  end
  table.sort(parts)
  return table.concat(parts, "\0")
end

function ClipboardHistory.new(options)
  options = options or {}
  local runtime = options.runtime or {}
  return setmetatable({
    chooserFactory = assert(options.chooserFactory),
    excludedBundleIDs = options.excludedBundleIDs or {},
    maxEntries = options.maxEntries or 100,
    entries = {},
    frontmostApplication = runtime.frontmostApplication or hs.application.frontmostApplication,
    focusedWindow = runtime.focusedWindow or hs.window.focusedWindow,
    keyStroke = runtime.keyStroke or hs.eventtap.keyStroke,
    readAllData = runtime.readAllData or hs.pasteboard.readAllData,
    readImage = runtime.readImage or hs.pasteboard.readImage,
    readString = runtime.readString or hs.pasteboard.readString,
    writeAllData = runtime.writeAllData or hs.pasteboard.writeAllData,
    watcherNew = runtime.watcherNew or hs.pasteboard.watcher.new,
    doAfter = runtime.doAfter or hs.timer.doAfter,
  }, ClipboardHistory)
end

function ClipboardHistory:_capture()
  local application = self.frontmostApplication()
  local bundleID = application and application:bundleID()
  if bundleID and self.excludedBundleIDs[bundleID] then return end

  local data = self.readAllData()
  if not data or not next(data) then return end
  local signature = fingerprint(data)
  if signature == "" then return end
  local text = self.readString()
  local image = not text and self.readImage() or nil
  local label = text and oneLine(text) or (image and "Image" or "Clipboard item")
  if label == "" then label = "Empty text" end

  for index, entry in ipairs(self.entries) do
    if entry.signature == signature then table.remove(self.entries, index); break end
  end
  table.insert(self.entries, 1, {
    data = data,
    image = image,
    label = label,
    signature = signature,
  })
  while #self.entries > self.maxEntries do table.remove(self.entries) end
end

function ClipboardHistory:open()
  if #self.entries == 0 then return end
  local origin = self.focusedWindow()
  local choices = {}
  for _, entry in ipairs(self.entries) do
    choices[#choices + 1] = {text = entry.label, image = entry.image, entry = entry}
  end
  local chooser = self.chooserFactory()
  chooser:show(choices, function(selected)
    if not selected then return end
    if origin then origin:focus() end
    self.writeAllData(selected.entry.data)
    self.doAfter(0.08, function() self.keyStroke({"cmd"}, "v", 0) end)
  end, origin and origin:screen())
end

function ClipboardHistory:start()
  self:_capture()
  self.watcher = self.watcherNew(function() self:_capture() end)
  return self
end

return ClipboardHistory
