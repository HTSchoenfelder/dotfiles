local planner = require("modules.layout_planner")

local LayoutOrchestrator = {}
LayoutOrchestrator.__index = LayoutOrchestrator

local function report(requestError)
  if not requestError or requestError.kind == "stale" then return end
  hs.notify.new({
    title = "AeroSpace",
    informativeText = requestError.message ~= "" and requestError.message
      or "Window operation failed",
  }):send()
end

function LayoutOrchestrator.new(client, repository, gate, workspaces)
  return setmetatable({
    client = client,
    repository = repository,
    gate = gate,
    workspaces = workspaces,
  }, LayoutOrchestrator)
end

function LayoutOrchestrator:activate(target, request, callback)
  callback = callback or function() end
  if not self.gate:isCurrent(request.generation) then return end
  self.repository:listWorkspace(request.workspace, function(windows, requestError)
    if requestError then report(requestError); callback(false); return end
    if not self.gate:isCurrent(request.generation) then return end
    local commands = planner.activation(
      target,
      request.workspace,
      windows,
      self.workspaces.parking,
      request.mode
    )
    self.client:eval(commands, function(_, mutationError)
      if mutationError then report(mutationError); callback(false); return end
      callback(true)
    end, "layout")
  end, "layout_snapshot")
end

LayoutOrchestrator.report = report

return LayoutOrchestrator
