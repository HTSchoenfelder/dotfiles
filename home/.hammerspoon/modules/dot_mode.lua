local catalog = require("shortcut_catalog")
local textData = require("modules.text_data")

local DotMode = {}
DotMode.__index = DotMode

local function screenshotPath(directory)
  local timestamp = os.date("%Y-%m-%d at %H.%M.%S")
  hs.fs.mkdir(directory)
  return directory .. "/Screen Shot " .. timestamp .. ".png"
end

function DotMode.new(options)
  options.tasks = {}
  options.taskSerial = 0
  return setmetatable(options, DotMode)
end

function DotMode:_run(path, arguments)
  self.taskSerial = self.taskSerial + 1
  local serial = self.taskSerial
  local task
  task = hs.task.new(path, function(exitCode, _, stderr)
    self.tasks[serial] = nil
    if exitCode ~= 0 and stderr ~= "" then
      hs.notify.new({title = "Dot mode", informativeText = stderr}):send()
    end
  end, arguments)
  self.tasks[serial] = task
  task:start()
end

function DotMode:_notice()
  local screen = hs.window.focusedWindow() and hs.window.focusedWindow():screen()
    or hs.screen.mainScreen()
  local frame = screen:frame()
  local width, height = 120, 32
  self.notice = hs.canvas.new({
    x = frame.x + frame.w - width - 16,
    y = frame.y + 16,
    w = width,
    h = height,
  })
  self.notice:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = {white = 0.12, alpha = 0.92},
    roundedRectRadii = {xRadius = 7, yRadius = 7},
  }, {
    type = "text",
    text = "dot mode",
    textColor = {white = 0.92, alpha = 1},
    textSize = 15,
    textAlignment = "center",
    frame = {x = "0%", y = "12%", w = "100%", h = "80%"},
  })
  self.notice:level(hs.canvas.windowLevels.status)
  self.notice:behaviorAsLabels({"canJoinAllSpaces", "stationary", "ignoresCycle"})
  self.notice:show()
end

function DotMode:exit()
  if self.keyTap then self.keyTap:stop() end
  if self.notice then self.notice:delete(); self.notice = nil end
  if self.modal then self.modal:exit() end
end

function DotMode:enter()
  if self.notice then return end
  self:_notice()
  self.modal:enter()
  self.keyTap:start()
end

function DotMode:_action(callback)
  return function()
    self:exit()
    hs.timer.doAfter(0, callback)
  end
end

function DotMode:_captureRegion()
  self:_run("/usr/sbin/screencapture", {"-i", "-s", screenshotPath(self.screenshotDirectory)})
end

function DotMode:_captureWindow()
  local window = hs.window.focusedWindow()
  if window and window:id() then
    self:_run("/usr/sbin/screencapture", {
      "-l", tostring(window:id()), screenshotPath(self.screenshotDirectory),
    })
  end
end

function DotMode:_captureScreen()
  local window = hs.window.focusedWindow()
  local screen = window and window:screen() or hs.screen.mainScreen()
  local frame = screen:fullFrame()
  local rectangle = string.format("%d,%d,%d,%d", frame.x, frame.y, frame.w, frame.h)
  self:_run("/usr/sbin/screencapture", {
    "-R", rectangle, screenshotPath(self.screenshotDirectory),
  })
end

function DotMode:_commands()
  local chooser = self.chooserFactory()
  chooser:show({{text = "Reset window layout"}}, function(selected)
    if selected then self.resetLayout() end
  end)
end

function DotMode:_bind(modifiers, key, callback, description)
  self.modal:bind(modifiers, key, self:_action(callback))
  local prefix = "MainMod + . → "
  local label = (#modifiers > 0 and "Shift + " or "") .. key:upper()
  catalog.add("Dot mode", prefix .. label, description)
end

function DotMode:start()
  self.modal = hs.hotkey.modal.new()
  self.binding = hs.hotkey.bind(self.modifiers, ".", function() self:enter() end)
  catalog.add("Dot mode", "MainMod + .", "Enter dot mode")

  self:_bind({}, "q", function() self:_captureRegion() end, "Capture region")
  self:_bind({}, "a", function() self:_captureWindow() end, "Capture focused window")
  self:_bind({}, "z", function() self:_captureScreen() end, "Capture focused monitor")
  self:_bind({}, "g", function() self.overlays:toggle("editor") end, "Toggle project editor")
  self:_bind({"shift"}, "g", function() self.overlays:toggle("git") end, "Toggle project Git client")
  self:_bind({}, "j", function() self.overlays:toggle("terminal") end, "Toggle project terminal")
  self:_bind({}, "e", function()
    self.textLauncher:open(self.emojiPath, textData.emoji)
  end, "Insert emoji")
  self:_bind({}, "r", function() self:_commands() end, "Reset window layout")
  self:_bind({}, "t", function()
    self.textLauncher:open(self.snippetPath, textData.snippet)
  end, "Insert snippet")
  self.modal:bind({}, "escape", function() self:exit() end)
  catalog.add("Dot mode", "MainMod + . → Escape", "Leave dot mode")

  local recognized = {}
  for _, key in ipairs({"q", "a", "z", "g", "j", "e", "r", "t", "escape"}) do
    recognized[hs.keycodes.map[key]] = true
  end
  self.keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if not recognized[event:getKeyCode()] then self:exit() end
    return false
  end)
end

return DotMode
