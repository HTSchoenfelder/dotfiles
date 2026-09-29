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

local function centeredFrame(screen)
  local frame = screen:frame()
  local width, height = math.floor(frame.w * 0.8), math.floor(frame.h * 0.8)
  return {
    x = frame.x + math.floor((frame.w - width) / 2),
    y = frame.y + math.floor((frame.h - height) / 2),
    w = width,
    h = height,
  }
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
  self.repository:listAll(function(records)
    for _, record in ipairs(records or {}) do
      if not record.minimized and record.title:match("^" .. prefix) then
        self.visibleOverlayID = record.id
        return
      end
    end
  end)
end

function ProjectOverlays:_hide(record)
  if record and record.window and not record.window:isMinimized() then record.window:minimize() end
  if record and self.visibleOverlayID == record.id then self.visibleOverlayID = nil end
end

function ProjectOverlays:_show(record, screen, generation)
  if not self.gate:isCurrent(generation) or not record or not record.window then return end
  if record.window:isMinimized() then record.window:unminimize() end
  hs.timer.doAfter(0.08, function()
    if not self.gate:isCurrent(generation)
        or not self.repository:isUsable(record.window) then return end
    record.window:setFrameWithWorkarounds(centeredFrame(screen), 0)
    record.window:focus()
    self.visibleOverlayID = record.id
  end)
end

function ProjectOverlays:_wait(title, screen, generation)
  local deadline = hs.timer.secondsSinceEpoch() + 15
  local function poll()
    self.repository:listAll(function(records)
      for _, record in ipairs(records) do
        if record.title == title then self:_show(record, screen, generation); return end
      end
      if hs.timer.secondsSinceEpoch() < deadline and self.gate:isCurrent(generation) then
        hs.timer.doAfter(0.1, poll)
      elseif self.gate:isCurrent(generation) then
        hs.notify.new({title = "Project overlay", informativeText = "Overlay window did not open"}):send()
      end
    end)
  end
  poll()
end

function ProjectOverlays:_launch(tool, project, screen, generation)
  local definition = self.tools[tool]
  if not definition or not hs.fs.attributes(definition.command[1]) then
    hs.notify.new({title = "Project overlay", informativeText = "Tool is not installed"}):send()
    return
  end
  local title = overlayTitle(tool, project)
  local arguments = {
    "-g", "-na", self.kittyApp, "--args", "-o", "dynamic_title=no",
    "--title", title, "--directory", project,
  }
  for _, argument in ipairs(definition.command) do arguments[#arguments + 1] = argument end
  local task
  task = hs.task.new("/usr/bin/open", function(exitCode)
    self.tasks[generation] = nil
    if exitCode == 0 then self:_wait(title, screen, generation) end
  end, arguments)
  self.tasks[generation] = task
  if not task:start() then self.tasks[generation] = nil end
end

function ProjectOverlays:toggle(tool)
  local focusedWindow = hs.window.focusedWindow()
  local project = projectFromWindow(focusedWindow)
  if not project then
    hs.notify.new({
      title = "Project overlay",
      informativeText = "Focus a path-based VS Code project or project overlay",
    }):send()
    return
  end
  local screen = focusedWindow and focusedWindow:screen() or hs.screen.mainScreen()
  local generation = self.gate:next()
  self.repository:listAll(function(records)
    if not self.gate:isCurrent(generation) then return end
    local title = overlayTitle(tool, project)
    local selected
    for _, record in ipairs(records) do
      if record.title:match("^" .. prefix) then
        if record.title == title then selected = record
        elseif not record.minimized then self:_hide(record) end
      end
    end
    if selected and not selected.minimized and selected.id == self.visibleOverlayID then
      self:_hide(selected)
    elseif selected then
      self:_show(selected, screen, generation)
    else
      self:_launch(tool, project, screen, generation)
    end
  end)
end

ProjectOverlays.projectFromWindow = projectFromWindow
ProjectOverlays.overlayTitle = overlayTitle
ProjectOverlays.overlayProject = overlayProject

return ProjectOverlays
