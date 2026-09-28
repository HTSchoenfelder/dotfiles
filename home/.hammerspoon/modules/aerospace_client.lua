local AerospaceClient = {}
AerospaceClient.__index = AerospaceClient

local windowFormat = table.concat({
  "%{window-id}",
  "%{app-bundle-id}",
  "%{app-name}",
  "%{window-title}",
  "%{window-parent-container-layout}",
  "%{workspace}",
  "%{workspace-is-focused}",
  "%{workspace-is-visible}",
  "%{monitor-id}",
}, " ")

local monitorFormat = table.concat({
  "%{monitor-id}",
  "%{monitor-name}",
  "%{monitor-is-main}",
}, " ")

local workspaceFormat = table.concat({
  "%{workspace}",
  "%{workspace-is-focused}",
  "%{workspace-is-visible}",
  "%{workspace-root-container-layout}",
  "%{monitor-id}",
  "%{monitor-name}",
  "%{monitor-is-main}",
}, " ")

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function copy(arguments)
  local result = {}
  for index, value in ipairs(arguments or {}) do
    assert(type(value) == "string", "AeroSpace arguments must be strings")
    result[index] = value
  end
  return result
end

local function classifyError(stderr)
  local message = trim(stderr)
  local lower = message:lower()
  if lower:find("config", 1, true) and
      (lower:find("error", 1, true) or lower:find("invalid", 1, true)) then
    return "invalid_config", message
  end
  if lower:find("server is not responding", 1, true) or
      lower:find("can't connect", 1, true) then
    return "unavailable", message
  end
  return "command_failed", message
end

local function errorRecord(kind, message, arguments, exitCode)
  return {
    kind = kind,
    message = message,
    arguments = arguments,
    exitCode = exitCode,
  }
end

function AerospaceClient.decodeJSON(output, decoder)
  local ok, value = pcall(decoder, output)
  if not ok or type(value) ~= "table" then
    return nil, errorRecord("invalid_json", "AeroSpace returned invalid JSON")
  end
  return value
end

function AerospaceClient.shellCommand(arguments)
  local tokens = {}
  for _, value in ipairs(arguments) do
    assert(type(value) == "string" and value:match("^[%w%._:%-]+$"),
      "Unsafe AeroSpace shell token: " .. tostring(value))
    tokens[#tokens + 1] = value
  end
  return table.concat(tokens, " ")
end

function AerospaceClient.new(options, runtime)
  runtime = runtime or {}
  local attributes = runtime.attributes or hs.fs.attributes
  local executable
  for _, candidate in ipairs(options.executableCandidates or {}) do
    if attributes(candidate) then
      executable = candidate
      break
    end
  end

  return setmetatable({
    executable = executable,
    taskNew = runtime.taskNew or hs.task.new,
    jsonDecode = runtime.jsonDecode or hs.json.decode,
    defer = runtime.defer or function(callback) hs.timer.doAfter(0, callback) end,
    after = runtime.after or function(delay, callback) hs.timer.doAfter(delay, callback) end,
    tasks = {},
    taskByKey = {},
    latestByKey = {},
    requestSerial = 0,
    eventListeners = {},
    eventBuffer = "",
    eventsEnabled = false,
  }, AerospaceClient)
end

function AerospaceClient:_dispatchEvent(line)
  if line == "" then return end
  local event = AerospaceClient.decodeJSON(line, self.jsonDecode)
  if not event then return end
  for _, callback in ipairs(self.eventListeners[event._event] or {}) do
    callback(event)
  end
end

function AerospaceClient:_consumeEvents(output)
  self.eventBuffer = self.eventBuffer .. (output or "")
  while true do
    local newline = self.eventBuffer:find("\n", 1, true)
    if not newline then break end
    local line = self.eventBuffer:sub(1, newline - 1)
    self.eventBuffer = self.eventBuffer:sub(newline + 1)
    self:_dispatchEvent(line)
  end
end

function AerospaceClient:_startEventStream()
  if not self.eventsEnabled or not self.executable or self.eventTask then return end
  local events = {}
  for name in pairs(self.eventListeners) do events[#events + 1] = name end
  table.sort(events)
  if #events == 0 then return end
  local arguments = {"subscribe"}
  for _, name in ipairs(events) do arguments[#arguments + 1] = name end

  local task
  task = self.taskNew(self.executable, function(_, stdout)
    self:_consumeEvents(stdout)
    if self.eventTask == task then self.eventTask = nil end
    if self.eventsEnabled then
      self.after(1, function() self:_startEventStream() end)
    end
  end, function(_, stdout)
    self:_consumeEvents(stdout)
    return true
  end, arguments)
  self.eventTask = task
  if not task or not task:start() then
    self.eventTask = nil
    self.after(1, function() self:_startEventStream() end)
  end
end

function AerospaceClient:onEvent(name, callback)
  self.eventListeners[name] = self.eventListeners[name] or {}
  self.eventListeners[name][#self.eventListeners[name] + 1] = callback
  self.eventsEnabled = true
  self:_startEventStream()
end

function AerospaceClient:run(arguments, callback, options)
  arguments = copy(arguments)
  callback = callback or function() end
  options = options or {}
  self.requestSerial = self.requestSerial + 1
  local requestID = self.requestSerial

  if options.key then
    local previous = self.taskByKey[options.key]
    if previous and previous:isRunning() then previous:terminate() end
    self.latestByKey[options.key] = requestID
  end

  if not self.executable then
    self.defer(function()
      callback(nil, errorRecord(
        "unavailable",
        "AeroSpace CLI is not installed in a configured path",
        arguments
      ))
    end)
    return requestID
  end

  local task
  task = self.taskNew(self.executable, function(exitCode, stdout, stderr)
    self.tasks[requestID] = nil
    if options.key and self.taskByKey[options.key] == task then
      self.taskByKey[options.key] = nil
    end
    if options.key and self.latestByKey[options.key] ~= requestID then
      callback(nil, errorRecord("stale", "A newer AeroSpace request superseded this response", arguments))
      return
    end
    if exitCode ~= 0 then
      local kind, message = classifyError(stderr ~= "" and stderr or stdout)
      callback(nil, errorRecord(kind, message, arguments, exitCode))
      return
    end
    callback(stdout, nil)
  end, arguments)

  if not task then
    self.defer(function()
      callback(nil, errorRecord("unavailable", "Could not create AeroSpace task", arguments))
    end)
    return requestID
  end

  self.tasks[requestID] = task
  if options.key then self.taskByKey[options.key] = task end
  if not task:start() then
    self.tasks[requestID] = nil
    if options.key and self.taskByKey[options.key] == task then
      self.taskByKey[options.key] = nil
    end
    self.defer(function()
      callback(nil, errorRecord("unavailable", "Could not start AeroSpace task", arguments))
    end)
  end
  return requestID
end

function AerospaceClient:query(arguments, callback, options)
  local queryArguments = copy(arguments)
  queryArguments[#queryArguments + 1] = "--json"
  if options and options.format then
    queryArguments[#queryArguments + 1] = "--format"
    queryArguments[#queryArguments + 1] = options.format
  end
  return self:run(queryArguments, function(output, requestError)
    if requestError then
      callback(nil, requestError)
      return
    end
    local records, decodeError = AerospaceClient.decodeJSON(output, self.jsonDecode)
    callback(records, decodeError)
  end, options)
end

function AerospaceClient:listWindows(scopeArguments, callback, key)
  local arguments = {"list-windows"}
  for _, value in ipairs(scopeArguments or {"--all"}) do
    arguments[#arguments + 1] = value
  end
  return self:query(arguments, callback, {key = key, format = windowFormat})
end

function AerospaceClient:listMonitors(callback, key)
  return self:query({"list-monitors"}, callback, {key = key, format = monitorFormat})
end

function AerospaceClient:listWorkspaces(arguments, callback, key)
  local command = {"list-workspaces"}
  for _, value in ipairs(arguments or {"--all"}) do
    command[#command + 1] = value
  end
  return self:query(command, callback, {key = key, format = workspaceFormat})
end

function AerospaceClient:execute(arguments, callback, key)
  return self:run(arguments, callback, {key = key})
end

function AerospaceClient:eval(commands, callback, key)
  if #commands == 0 then
    self.defer(function() (callback or function() end)("", nil) end)
    return
  end
  local expression = {}
  for _, command in ipairs(commands) do
    expression[#expression + 1] = AerospaceClient.shellCommand(command)
  end
  return self:execute({"eval", table.concat(expression, "; ")}, callback, key)
end

function AerospaceClient:focusWindow(windowID, callback, key)
  return self:execute({"focus", "--window-id", tostring(windowID)}, callback, key)
end

function AerospaceClient:moveWindowToWorkspace(windowID, workspace, callback, key)
  return self:execute({
    "move-node-to-workspace", "--window-id", tostring(windowID), tostring(workspace),
  }, callback, key)
end

function AerospaceClient:focusWorkspace(workspace, callback, key)
  return self:execute({"workspace", tostring(workspace)}, callback, key)
end

function AerospaceClient:cancelAll()
  self.eventsEnabled = false
  if self.eventTask and self.eventTask:isRunning() then self.eventTask:terminate() end
  self.eventTask = nil
  for _, task in pairs(self.tasks) do
    if task:isRunning() then task:terminate() end
  end
  self.tasks = {}
  self.taskByKey = {}
end

return AerospaceClient
