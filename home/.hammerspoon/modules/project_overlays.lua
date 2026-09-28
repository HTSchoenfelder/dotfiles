local orchestratorModule = require("modules.layout_orchestrator")

local ProjectOverlays = {}
ProjectOverlays.__index = ProjectOverlays

local prefix = "project-overlay-"

local function hexEncode(value)
  return (value:gsub(".", function(character)
    return string.format("%02x", string.byte(character))
  end))
end

local function hexDecode(value)
  return (value:gsub("%x%x", function(pair)
    return string.char(tonumber(pair, 16))
  end))
end

local function overlayTitle(tool, project)
  return prefix .. tool .. "-" .. hexEncode(project)
end

local function overlayProject(title)
  local _, encoded = title:match("^" .. prefix .. "([a-z]+)%-(%x+)$")
  if not encoded then return nil end
  return hexDecode(encoded)
end

local function projectFromWindow(window)
  if not window then return nil end
  local application = window:application()
  local title = window:title() or ""
  if application and application:bundleID() == "com.microsoft.VSCode" then
    local candidate = title:match("^(.-) | Code$")
    if candidate and candidate:sub(1, 2) == "~/" then
      candidate = os.getenv("HOME") .. candidate:sub(2)
    end
    if candidate and hs.fs.attributes(candidate, "mode") == "directory" then return candidate end
  end
  return overlayProject(title)
end

function ProjectOverlays.new(options)
  options.tools = {
    editor = {command = {"/run/current-system/sw/bin/nvim"}},
    git = {command = {"/run/current-system/sw/bin/lazygit"}},
    terminal = {command = {"/bin/zsh"}},
  }
  options.tasks = {}
  return setmetatable(options, ProjectOverlays)
end

function ProjectOverlays:start()
  self.client:onEvent("focused-workspace-changed", function(event)
    if self.visibleOverlayID and event.workspace ~= self.visibleWorkspace then
      local windowID = self.visibleOverlayID
      self.visibleOverlayID = nil
      self.visibleWorkspace = nil
      self.client:moveWindowToWorkspace(windowID, self.workspaces.overlays, function(_, requestError)
        if requestError then orchestratorModule.report(requestError) end
      end, "project_overlay_hide")
    end
  end)
  self.repository:listAll(function(records)
    for _, record in ipairs(records or {}) do
      if record.workspaceVisible and record.title:match("^" .. prefix) then
        self.visibleOverlayID = record.id
        self.visibleWorkspace = record.workspace
        return
      end
    end
  end, "project_overlay_seed")
end

function ProjectOverlays:_show(record, workspace, generation)
  if not self.gate:isCurrent(generation) then return end
  self.client:eval({
    {"move-node-to-workspace", "--window-id", tostring(record.id), workspace},
    {"layout", "--window-id", tostring(record.id), "floating"},
    {"focus", "--window-id", tostring(record.id)},
  }, function(_, requestError)
    if requestError then orchestratorModule.report(requestError) end
    if not requestError then
      self.visibleOverlayID = record.id
      self.visibleWorkspace = workspace
    end
  end, "project_overlay")
end

function ProjectOverlays:_wait(title, workspace, generation)
  local deadline = hs.timer.secondsSinceEpoch() + 15
  local function poll()
    self.repository:listAll(function(records, requestError)
      if requestError then orchestratorModule.report(requestError); return end
      for _, record in ipairs(records) do
        if record.title == title then self:_show(record, workspace, generation); return end
      end
      if hs.timer.secondsSinceEpoch() < deadline and self.gate:isCurrent(generation) then
        hs.timer.doAfter(0.1, poll)
      elseif self.gate:isCurrent(generation) then
        hs.notify.new({title = "Project overlay", informativeText = "Overlay window did not open"}):send()
      end
    end, "overlay_poll_" .. tostring(generation))
  end
  poll()
end

function ProjectOverlays:_launch(tool, project, workspace, generation)
  local definition = self.tools[tool]
  if not definition or not hs.fs.attributes(definition.command[1]) then
    hs.notify.new({title = "Project overlay", informativeText = "Tool is not installed"}):send()
    return
  end
  local title = overlayTitle(tool, project)
  local arguments = {
    "-na", self.kittyApp, "--args", "-o", "dynamic_title=no",
    "--title", title, "--directory", project,
  }
  for _, argument in ipairs(definition.command) do arguments[#arguments + 1] = argument end
  local task
  task = hs.task.new("/usr/bin/open", function(exitCode)
    self.tasks[generation] = nil
    if exitCode == 0 then self:_wait(title, workspace, generation) end
  end, arguments)
  self.tasks[generation] = task
  task:start()
end

function ProjectOverlays:toggle(tool)
  local project = projectFromWindow(hs.window.focusedWindow())
  if not project then
    hs.notify.new({
      title = "Project overlay",
      informativeText = "Focus a path-based VS Code project or project overlay",
    }):send()
    return
  end
  local generation = self.gate:next()
  self.repository:listAll(function(records, requestError)
    if requestError then orchestratorModule.report(requestError); return end
    if not self.gate:isCurrent(generation) then return end
    local focused = self.repository:focusedRecord(records)
    local workspace = focused and focused.workspace or self.workspaces.terminal
    local title = overlayTitle(tool, project)
    local selected
    local commands = {}
    for _, record in ipairs(records) do
      if record.title:match("^" .. prefix) then
        if record.title == title then selected = record end
        if record.workspaceVisible and record.title ~= title then
          commands[#commands + 1] = {
            "move-node-to-workspace", "--window-id", tostring(record.id), self.workspaces.overlays,
          }
        end
      end
    end
    if selected and selected.workspace == workspace then
      self.visibleOverlayID = nil
      self.visibleWorkspace = nil
      commands[#commands + 1] = {
        "move-node-to-workspace", "--window-id", tostring(selected.id), self.workspaces.overlays,
      }
    end
    self.client:eval(commands, function(_, mutationError)
      if mutationError then orchestratorModule.report(mutationError); return end
      if selected and selected.workspace ~= workspace then
        self:_show(selected, workspace, generation)
      elseif not selected then
        self:_launch(tool, project, workspace, generation)
      end
    end, "project_overlay")
  end, "project_overlay_snapshot")
end

ProjectOverlays.projectFromWindow = projectFromWindow
ProjectOverlays.overlayTitle = overlayTitle
ProjectOverlays.overlayProject = overlayProject

return ProjectOverlays
