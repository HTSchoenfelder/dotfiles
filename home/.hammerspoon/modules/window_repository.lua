local WindowRepository = {}
WindowRepository.__index = WindowRepository

local function call(window, method, fallback)
  if not window or type(window[method]) ~= "function" then return fallback end
  local ok, value = pcall(window[method], window)
  if ok then return value end
  return fallback
end

local function screenIdentifier(screen)
  if not screen then return nil end
  return call(screen, "getUUID") or tostring(call(screen, "id", "unknown"))
end

local function isUsable(window, allowFullScreen)
  local id = call(window, "id")
  return id ~= nil
    and call(window, "isStandard", true) ~= false
    and (allowFullScreen or call(window, "isFullScreen", false) ~= true)
end

local function record(window, allowFullScreen)
  if not isUsable(window, allowFullScreen) then return nil end
  local application = call(window, "application")
  local screen = call(window, "screen")
  return {
    id = tonumber(call(window, "id")),
    title = call(window, "title", "") or "",
    bundleID = call(application, "bundleID", "") or "",
    appName = call(application, "name", "Window") or "Window",
    minimized = call(window, "isMinimized", false) == true,
    screen = screen,
    screenID = screenIdentifier(screen),
    window = window,
  }
end

function WindowRepository.new(history, runtime)
  runtime = runtime or {}
  return setmetatable({
    history = history,
    orderedWindows = runtime.orderedWindows or function() return hs.window.orderedWindows() end,
    allWindows = runtime.allWindows or function() return hs.window.allWindows() end,
    getWindow = runtime.getWindow or function(id) return hs.window.get(id) end,
    focusedWindow = runtime.focusedWindow or function() return hs.window.focusedWindow() end,
  }, WindowRepository)
end

function WindowRepository:isUsable(window)
  return isUsable(window)
end

function WindowRepository:record(window)
  return record(window)
end

function WindowRepository:borderRecord(window)
  return record(window, true)
end

function WindowRepository:recordForID(windowID)
  return record(self.getWindow(windowID))
end

function WindowRepository:listAll(callback)
  local records, seen = {}, {}
  local function append(windows)
    for _, window in ipairs(windows or {}) do
      local item = record(window)
      if item and not seen[item.id] then
        seen[item.id] = true
        records[#records + 1] = item
      end
    end
  end
  append(self.orderedWindows())
  append(self.allWindows())
  callback(records, nil)
end

function WindowRepository:focusedRecord(records)
  local focusedID = call(self.focusedWindow(), "id")
  for _, item in ipairs(records or {}) do
    if item.id == focusedID then return item end
  end
end

function WindowRepository:orderedByHistory(records)
  return self.history:sort(records)
end

function WindowRepository:matchingBundle(records, bundleID)
  local matches = {}
  for _, item in ipairs(records or {}) do
    if item.bundleID == bundleID then matches[#matches + 1] = item end
  end
  return self:orderedByHistory(matches)
end

WindowRepository.screenIdentifier = screenIdentifier
WindowRepository.isUsableWindow = isUsable
WindowRepository.windowRecord = record

return WindowRepository
