local ApplicationNavigation = {}
ApplicationNavigation.__index = ApplicationNavigation

local function choice(record)
  local title = record.title ~= "" and record.title or record.appName
  return {text = record.appName .. " — " .. title, id = record.id, record = record}
end

function ApplicationNavigation.new(options)
  return setmetatable({
    client = options.client,
    repository = options.repository,
    orchestrator = options.orchestrator,
    chooserFactory = options.chooserFactory,
    gate = options.gate,
    workspaces = options.workspaces,
    timeout = options.launchTimeoutSeconds or 15,
    pollInterval = options.launchPollIntervalSeconds or 0.1,
    launchTasks = {},
  }, ApplicationNavigation)
end

function ApplicationNavigation:_request(application, mode, generation, records)
  local focused = self.repository:focusedRecord(records)
  return {
    application = application,
    generation = generation,
    mode = mode,
    workspace = focused and focused.workspace or self.workspaces.terminal,
  }
end

function ApplicationNavigation:_showOrChoose(windows, request, chooseInstance)
  if not self.gate:isCurrent(request.generation) then return end
  if chooseInstance then
    local choices = {}
    for _, window in ipairs(windows) do choices[#choices + 1] = choice(window) end
    local chooser = self.chooserFactory()
    chooser:show(choices, function(selected)
      if selected and self.gate:isCurrent(request.generation) then
        self.orchestrator:activate(selected.record, request)
      end
    end)
    return
  end
  self.orchestrator:activate(windows[1], request)
end

function ApplicationNavigation:_launch(application, running, generation, callback)
  if running and application.newWindowShortcut then
    hs.eventtap.keyStroke(
      application.newWindowShortcut.modifiers,
      application.newWindowShortcut.key,
      0,
      running
    )
    callback(true)
    return
  end

  local arguments = {}
  for name, value in pairs(application.launchEnvironment or {}) do
    arguments[#arguments + 1] = "--env"
    arguments[#arguments + 1] = name .. "=" .. value
  end
  arguments[#arguments + 1] = "-b"
  arguments[#arguments + 1] = application.bundleID
  local task
  task = hs.task.new("/usr/bin/open", function(exitCode)
    self.launchTasks[generation] = nil
    callback(exitCode == 0)
  end, arguments)
  self.launchTasks[generation] = task
  if not task:start() then
    self.launchTasks[generation] = nil
    callback(false)
  end
end

function ApplicationNavigation:_waitForWindow(application, request, chooseInstance, initialIDs)
  local deadline = hs.timer.secondsSinceEpoch() + self.timeout
  local function poll()
    self.repository:listAll(function(records, requestError)
      if requestError then
        if self.gate:isCurrent(request.generation) then
          require("modules.layout_orchestrator").report(requestError)
        end
        return
      end
      local windows = self.repository:matchingBundle(records, application.bundleID)
      if #windows > 0 then
        if self.gate:isCurrent(request.generation) then
          self:_showOrChoose(windows, request, chooseInstance)
        else
          for _, window in ipairs(windows) do
            if not initialIDs[window.id] then
              self.client:moveWindowToWorkspace(window.id, self.workspaces.parking)
            end
          end
        end
        return
      end
      if hs.timer.secondsSinceEpoch() >= deadline then
        if self.gate:isCurrent(request.generation) then
          hs.notify.new({
            title = "Hammerspoon",
            informativeText = "No window opened for " .. application.name,
          }):send()
        end
        return
      end
      hs.timer.doAfter(self.pollInterval, poll)
    end, "launch_poll_" .. tostring(request.generation))
  end
  poll()
end

function ApplicationNavigation:activate(application, mode, chooseInstance)
  local generation = self.gate:next()
  self.repository:listAll(function(records, requestError)
    if requestError then require("modules.layout_orchestrator").report(requestError); return end
    if not self.gate:isCurrent(generation) then return end
    local request = self:_request(application, mode, generation, records)
    local windows = self.repository:matchingBundle(records, application.bundleID)
    if #windows > 0 then
      self:_showOrChoose(windows, request, chooseInstance)
      return
    end

    local initialIDs = {}
    for _, record in ipairs(records) do initialIDs[record.id] = true end
    local running = hs.application.get(application.bundleID)
    self:_launch(application, running, generation, function(launched)
      if not launched then
        if self.gate:isCurrent(generation) then
          hs.notify.new({
            title = "Hammerspoon",
            informativeText = "Could not launch " .. application.name,
          }):send()
        end
        return
      end
      self:_waitForWindow(application, request, chooseInstance, initialIDs)
    end)
  end, "application_intent")
end

return ApplicationNavigation
