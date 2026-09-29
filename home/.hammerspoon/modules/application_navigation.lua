local ApplicationNavigation = {}
ApplicationNavigation.__index = ApplicationNavigation

local function choice(record)
  local title = record.title ~= "" and record.title or record.appName
  return {text = record.appName .. " — " .. title, id = record.id, record = record}
end

function ApplicationNavigation.new(options)
  return setmetatable({
    repository = options.repository,
    orchestrator = options.orchestrator,
    chooserFactory = options.chooserFactory,
    gate = options.gate,
    timeout = options.launchTimeoutSeconds or 15,
    pollInterval = options.launchPollIntervalSeconds or 0.1,
    launchTasks = {},
  }, ApplicationNavigation)
end

function ApplicationNavigation:_request(application, mode, generation, records)
  local focused = self.repository:focusedRecord(records)
  return {
    application = application,
    anchorID = focused and focused.id,
    generation = generation,
    mode = mode,
    screen = focused and focused.screen or self.orchestrator:activeScreen(),
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
    end, request.screen)
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

  local arguments = {"-g"}
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

function ApplicationNavigation:_waitForWindow(application, request, chooseInstance)
  local deadline = hs.timer.secondsSinceEpoch() + self.timeout
  local function poll()
    self.repository:listAll(function(records)
      local windows = self.repository:matchingBundle(records, application.bundleID)
      if #windows > 0 then
        if self.gate:isCurrent(request.generation) then
          self:_showOrChoose(windows, request, chooseInstance)
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
    end)
  end
  poll()
end

function ApplicationNavigation:activate(application, mode, chooseInstance)
  local generation = self.gate:next()
  self.repository:listAll(function(records)
    if not self.gate:isCurrent(generation) then return end
    local request = self:_request(application, mode, generation, records)
    local windows = self.repository:matchingBundle(records, application.bundleID)
    if #windows > 0 then
      self:_showOrChoose(windows, request, chooseInstance)
      return
    end

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
      self:_waitForWindow(application, request, chooseInstance)
    end)
  end)
end

return ApplicationNavigation
