local catalog = require("shortcut_catalog")
local textData = require("modules.text_data")

local DotMode = {}
DotMode.__index = DotMode

local function screenshotPath()
  local timestamp = os.date("%Y-%m-%d at %H.%M.%S")
  return os.getenv("HOME") .. "/Desktop/Screen Shot " .. timestamp .. ".png"
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
  self:_run("/usr/sbin/screencapture", {"-i", "-s", screenshotPath()})
end

function DotMode:_captureWindow()
  local window = hs.window.focusedWindow()
  if window and window:id() then
    self:_run("/usr/sbin/screencapture", {"-l", tostring(window:id()), screenshotPath()})
  end
end

function DotMode:_captureScreen()
  local window = hs.window.focusedWindow()
  local screen = window and window:screen() or hs.screen.mainScreen()
  local frame = screen:fullFrame()
  local rectangle = string.format("%d,%d,%d,%d", frame.x, frame.y, frame.w, frame.h)
  self:_run("/usr/sbin/screencapture", {"-R", rectangle, screenshotPath()})
end

function DotMode:_chooseDisplay()
  local choices = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    choices[#choices + 1] = {text = screen:name() .. " — enabled"}
  end
  local chooser = self.chooserFactory()
  chooser:show(choices, function(selected)
    if selected then
      hs.notify.new({
        title = "Display control",
        informativeText = "No supported display-toggle API is available",
      }):send()
    end
  end)
end

function DotMode:_commands()
  local chooser = self.chooserFactory()
  chooser:show({{text = "Reset workspaces", action = self.resetWorkspaces}}, function(selected)
    if selected then selected.action() end
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
  self:_bind({}, "b", function() self:_chooseDisplay() end, "Choose connected display")
  self:_bind({}, "g", function() self.overlays:toggle("editor") end, "Toggle project editor")
  self:_bind({"shift"}, "g", function() self.overlays:toggle("git") end, "Toggle project Git client")
  self:_bind({}, "j", function() self.overlays:toggle("terminal") end, "Toggle project terminal")
  self:_bind({}, "e", function()
    self.textLauncher:open(self.emojiPath, textData.emoji)
  end, "Insert emoji")
  self:_bind({}, "r", function() self:_commands() end, "Run configured command")
  self:_bind({}, "t", function()
    self.textLauncher:open(self.snippetPath, textData.snippet)
  end, "Insert snippet")
  self:_bind({}, "h", function() self.windows:moveFocusedToMonitor("prev") end,
    "Move focused window to previous display")
  self:_bind({}, "l", function() self.windows:moveFocusedToMonitor("next") end,
    "Move focused window to next display")
  self:_bind({"shift"}, "h", function() self.windows:moveVisibleToMonitor("prev") end,
    "Move visible windows to previous display")
  self:_bind({"shift"}, "l", function() self.windows:moveVisibleToMonitor("next") end,
    "Move visible windows to next display")
  self:_bind({}, "/", function() self.windows:toggleFullscreen() end,
    "Toggle focused window fullscreen")
  self.modal:bind({}, "escape", function() self:exit() end)
  catalog.add("Dot mode", "MainMod + . → Escape", "Leave dot mode")

  local recognized = {}
  for _, key in ipairs({"q", "a", "z", "b", "g", "j", "e", "r", "t", "h", "l", "/", "escape"}) do
    recognized[hs.keycodes.map[key]] = true
  end
  self.keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    if not recognized[event:getKeyCode()] then self:exit() end
    return false
  end)
end

return DotMode
