local orchestratorModule = require("modules.layout_orchestrator")

local WorkspaceNavigation = {}
WorkspaceNavigation.__index = WorkspaceNavigation

local labels = { ["1"] = "", ["2"] = "󰍹", ["10"] = "󰮍" }

local function normalize(record)
  return {
    id = tostring(record.workspace or record["workspace"]),
    focused = record["workspace-is-focused"] == true or record.workspaceIsFocused == true,
    visible = record["workspace-is-visible"] == true or record.workspaceIsVisible == true,
    monitorID = tonumber(record["monitor-id"] or record.monitorId),
  }
end

function WorkspaceNavigation.new(options)
  options.history = {}
  options.serial = 0
  local self = setmetatable(options, WorkspaceNavigation)
  self.client:onEvent("focused-workspace-changed", function(event)
    if event.workspace then self:remember(event.workspace) end
  end)
  return self
end

function WorkspaceNavigation:remember(workspace)
  self.serial = self.serial + 1
  self.history[tostring(workspace)] = self.serial
end

function WorkspaceNavigation:_list(callback)
  self.client:listWorkspaces({"--all"}, function(records, requestError)
    if requestError then orchestratorModule.report(requestError); return end
    local result = {}
    for _, record in ipairs(records) do
      local workspace = normalize(record)
      result[#result + 1] = workspace
      if workspace.focused then self:remember(workspace.id) end
    end
    callback(result)
  end, "workspace_snapshot")
end

function WorkspaceNavigation:switchPrimary()
  self.gate:next()
  self:_list(function(workspaces)
    local focused
    for _, workspace in ipairs(workspaces) do
      if workspace.focused then focused = workspace.id end
    end
    local target = focused == self.workspaces.terminal
      and self.workspaces.display or self.workspaces.terminal
    self.client:focusWorkspace(target, function(_, requestError)
      if requestError then orchestratorModule.report(requestError); return end
      self:remember(target)
    end, "workspace_focus")
  end)
end

function WorkspaceNavigation:commaItems(callback)
  self:_list(function(workspaces)
    table.sort(workspaces, function(first, second)
      local firstFocus = self.history[first.id] or -1
      local secondFocus = self.history[second.id] or -1
      if firstFocus ~= secondFocus then return firstFocus > secondFocus end
      local firstNumber = tonumber(first.id)
      local secondNumber = tonumber(second.id)
      if firstNumber and secondNumber then return firstNumber < secondNumber end
      return first.id < second.id
    end)
    local items = {}
    local currentID
    for _, workspace in ipairs(workspaces) do
      if workspace.id ~= self.workspaces.overlays then
        if workspace.focused then currentID = workspace.id end
        items[#items + 1] = {
          id = workspace.id,
          text = labels[workspace.id] or workspace.id,
          workspace = workspace,
        }
      end
    end
    callback(items, currentID)
  end)
end

function WorkspaceNavigation:focus(workspace, generation)
  if not self.gate:isCurrent(generation) then return end
  self.client:focusWorkspace(workspace.id, function(_, requestError)
    if requestError then orchestratorModule.report(requestError); return end
    self:remember(workspace.id)
  end, "workspace_focus")
end

WorkspaceNavigation.normalize = normalize

return WorkspaceNavigation
