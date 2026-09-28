local orchestratorModule = require("modules.layout_orchestrator")

local WindowNavigation = {}
WindowNavigation.__index = WindowNavigation

local function windowChoice(record)
  local title = record.title ~= "" and record.title or record.appName
  return {text = record.appName .. " — " .. title, id = record.id, record = record}
end

function WindowNavigation.new(options)
  return setmetatable(options, WindowNavigation)
end

function WindowNavigation:_records(callback, key)
  self.repository:listAll(function(records, requestError)
    if requestError then orchestratorModule.report(requestError); return end
    callback(records)
  end, key)
end

function WindowNavigation:chooseAny(mode)
  local generation = self.gate:next()
  self:_records(function(records)
    if not self.gate:isCurrent(generation) then return end
    local focused = self.repository:focusedRecord(records)
    local workspace = focused and focused.workspace or self.workspaces.terminal
    local choices = {}
    for _, record in ipairs(self.repository:orderedByHistory(records)) do
      if record.tiled ~= false then choices[#choices + 1] = windowChoice(record) end
    end
    local chooser = self.chooserFactory()
    chooser:show(choices, function(selected)
      if selected and self.gate:isCurrent(generation) then
        self.orchestrator:activate(selected.record, {
          generation = generation,
          mode = mode,
          workspace = workspace,
        })
      end
    end)
  end, "window_chooser")
end

function WindowNavigation:commaItems(instancesOnly, callback)
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    local ordered = self.repository:orderedByHistory(records)
    local items = {}
    for _, record in ipairs(ordered) do
      if record.tiled ~= false and (not instancesOnly or (focused and record.bundleID == focused.bundleID)) then
        items[#items + 1] = windowChoice(record)
      end
    end
    callback(items, focused)
  end, "window_comma")
end

function WindowNavigation:activateComma(record, mode, workspace, generation)
  if self.gate:isCurrent(generation) then
    self.orchestrator:activate(record, {
      generation = generation,
      mode = mode,
      workspace = workspace,
    })
  end
end

function WindowNavigation:focusNext()
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused then return end
    local workspaceWindows = {}
    local focusedIndex
    for _, record in ipairs(records) do
      if record.workspace == focused.workspace and record.tiled then
        workspaceWindows[#workspaceWindows + 1] = record
        if record.id == focused.id then focusedIndex = #workspaceWindows end
      end
    end
    if #workspaceWindows < 2 then return end
    local target = workspaceWindows[(focusedIndex or 0) % #workspaceWindows + 1]
    self.client:focusWindow(target.id, function(_, requestError)
      if requestError then orchestratorModule.report(requestError) end
    end, "direct_navigation")
  end, "direct_snapshot")
end

function WindowNavigation:rotatePositions()
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused then return end
    local count = 0
    for _, record in ipairs(records) do
      if record.workspace == focused.workspace and record.tiled then count = count + 1 end
    end
    if count < 2 then return end
    self.client:execute({
      "swap", "--window-id", tostring(focused.id), "--swap-focus", "--wrap-around", "dfs-next",
    }, function(_, requestError)
      if requestError then orchestratorModule.report(requestError) end
    end, "direct_navigation")
  end, "direct_snapshot")
end

function WindowNavigation:closeFocused()
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused then return end
    self.client:execute({"close", "--window-id", tostring(focused.id)}, function(_, requestError)
      if requestError then orchestratorModule.report(requestError) end
    end, "direct_navigation")
  end, "direct_snapshot")
end

function WindowNavigation:moveFocusedToMonitor(direction)
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused then return end
    self.client:execute({
      "move-node-to-monitor", "--window-id", tostring(focused.id),
      "--focus-follows-window", "--wrap-around", direction,
    }, function(_, requestError)
      if requestError then orchestratorModule.report(requestError) end
    end, "direct_navigation")
  end, "direct_snapshot")
end

function WindowNavigation:moveVisibleToMonitor(direction)
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused or not focused.monitorID then return end
    self.client:listMonitors(function(monitors, monitorError)
      if monitorError then orchestratorModule.report(monitorError); return end
      local count = #monitors
      if count < 2 then return end
      local offset = direction == "prev" and -1 or 1
      local target = (focused.monitorID - 1 + offset) % count + 1
      local commands = {}
      for _, record in ipairs(records) do
        if record.workspaceVisible then
          commands[#commands + 1] = {
            "move-node-to-monitor", "--window-id", tostring(record.id), tostring(target),
          }
        end
      end
      self.client:eval(commands, function(_, requestError)
        if requestError then orchestratorModule.report(requestError) end
      end, "direct_navigation")
    end, "monitor_snapshot")
  end, "direct_snapshot")
end

function WindowNavigation:toggleFullscreen()
  self.gate:next()
  self:_records(function(records)
    local focused = self.repository:focusedRecord(records)
    if not focused then return end
    self.client:execute({"fullscreen", "--window-id", tostring(focused.id)}, function(_, requestError)
      if requestError then orchestratorModule.report(requestError) end
    end, "direct_navigation")
  end, "direct_snapshot")
end

WindowNavigation.windowChoice = windowChoice

return WindowNavigation
