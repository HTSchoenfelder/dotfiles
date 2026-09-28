local WindowRepository = {}
WindowRepository.__index = WindowRepository

local function field(record, ...)
  for index = 1, select("#", ...) do
    local key = select(index, ...)
    if record[key] ~= nil then return record[key] end
  end
end

local function normalize(record)
  local id = tonumber(field(record, "window-id", "windowId", "window_id", "id"))
  if not id then return nil end
  local layout = field(record, "window-parent-container-layout", "windowLayout", "layout")
  return {
    id = id,
    title = field(record, "window-title", "windowTitle", "title") or "",
    bundleID = field(record, "app-bundle-id", "appBundleId", "bundleID") or "",
    appName = field(record, "app-name", "appName") or "Window",
    layout = layout,
    tiled = layout ~= "floating",
    workspace = tostring(field(record, "workspace") or ""),
    workspaceFocused = field(record, "workspace-is-focused", "workspaceIsFocused") == true,
    workspaceVisible = field(record, "workspace-is-visible", "workspaceIsVisible") == true,
    monitorID = tonumber(field(record, "monitor-id", "monitorId")),
    raw = record,
  }
end

function WindowRepository.new(client, history, runtime)
  runtime = runtime or {}
  return setmetatable({
    client = client,
    history = history,
    getWindow = runtime.getWindow or function(id) return hs.window.get(id) end,
    focusedWindow = runtime.focusedWindow or function() return hs.window.focusedWindow() end,
  }, WindowRepository)
end

function WindowRepository:decode(records)
  local result = {}
  for _, raw in ipairs(records or {}) do
    local record = normalize(raw)
    if record then
      local window = self.getWindow(record.id)
      if not window or (window:isStandard() and not window:isFullScreen()) then
        record.window = window
        result[#result + 1] = record
      end
    end
  end
  return result
end

function WindowRepository:listAll(callback, key)
  self.client:listWindows({"--all"}, function(records, requestError)
    if requestError then callback(nil, requestError); return end
    callback(self:decode(records), nil)
  end, key)
end

function WindowRepository:listWorkspace(workspace, callback, key)
  self.client:listWindows({"--workspace", tostring(workspace)}, function(records, requestError)
    if requestError then callback(nil, requestError); return end
    callback(self:decode(records), nil)
  end, key)
end

function WindowRepository:focusedRecord(records)
  local focused = self.focusedWindow()
  local focusedID = focused and focused:id()
  for _, record in ipairs(records or {}) do
    if record.id == focusedID then return record end
  end
  for _, record in ipairs(records or {}) do
    if record.workspaceFocused then return record end
  end
  return nil
end

function WindowRepository:orderedByHistory(records)
  return self.history:sort(records)
end

function WindowRepository:matchingBundle(records, bundleID)
  local matches = {}
  for _, record in ipairs(records or {}) do
    if record.bundleID == bundleID and record.tiled ~= false then
      matches[#matches + 1] = record
    end
  end
  return self:orderedByHistory(matches)
end

WindowRepository.normalize = normalize

return WindowRepository
