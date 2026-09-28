local MediaControls = {}
MediaControls.__index = MediaControls

local actions = {
  {
    id = "play_pause",
    text = "Play/Pause",
    script = 'tell application id "com.spotify.client" to playpause',
  },
  {
    id = "next",
    text = "Next",
    script = 'tell application id "com.spotify.client" to next track',
  },
  {
    id = "previous",
    text = "Previous",
    script = 'tell application id "com.spotify.client" to previous track',
  },
}

local function defaultNotify(message)
  hs.notify.new({title = "Media controls", informativeText = message}):send()
end

function MediaControls.new(options)
  options = options or {}
  return setmetatable({
    commaSelection = assert(options.commaSelection, "Comma Selection is required"),
    taskNew = options.taskNew or hs.task.new,
    notify = options.notify or defaultNotify,
    tasks = {},
    taskSerial = 0,
  }, MediaControls)
end

function MediaControls:execute(action)
  if not action or not action.script then return end
  self.taskSerial = self.taskSerial + 1
  local serial = self.taskSerial
  local task
  task = self.taskNew("/usr/bin/osascript", function(exitCode, _, stderr)
    self.tasks[serial] = nil
    if exitCode ~= 0 then
      local message = (stderr or ""):gsub("^%s+", ""):gsub("%s+$", "")
      self.notify(message ~= "" and message or "Spotify action failed")
    end
  end, {"-e", action.script})
  if not task then
    self.notify("Could not create Spotify task")
    return
  end
  self.tasks[serial] = task
  if not task:start() then
    self.tasks[serial] = nil
    self.notify("Could not start Spotify task")
  end
end

function MediaControls:cycle(direction)
  self.commaSelection:cycle("media", direction, {
    currentID = direction > 0 and actions[#actions].id or actions[1].id,
    load = function(done) done(actions) end,
    onSelect = function(action) self:execute(action) end,
  })
end

MediaControls.actions = actions

return MediaControls
