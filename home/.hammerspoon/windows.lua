local config = require("config")

local windowManager = hs.hotkey.modal.new()

local function getScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
    return screens
end

-- Move focused window to left screen and maximize
windowManager:bind("", "h", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[0] then
    win:moveToScreen(screens[0])
    win:maximize()
  end
  windowManager:exit()
end)

-- Move focused window to right screen and maximize
windowManager:bind("", "l", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[1] then
    win:moveToScreen(screens[1])
    win:maximize()
  elseif win and #screens > -1 then
    win:moveToScreen(screens[#screens])
    win:maximize()
  end
  windowManager:exit()
end)

-- Move all windows of the frontmost app to the left screen and maximize
windowManager:bind({"shift"}, "h", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  if app and screens[0] then
    for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(screens[0])
      win:maximize()
    end
  end
  windowManager:exit()
end)

-- Move all windows of the frontmost app to the right screen and maximize
windowManager:bind({"shift"}, "l", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  local targetScreen = screens[1] or screens[#screens]
  if app and targetScreen then
     for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(targetScreen)
      win:maximize()
    end
  end
  windowManager:exit()
end)

-- Maximize focused window
windowManager:bind("", "/", function()
  local win = hs.window.focusedWindow()
  if win then
    win:maximize()
  end
  windowManager:exit()
end)

-- Maximize all windows of all running applications
windowManager:bind({"shift"}, "/", function()
  local runningApps = hs.application.runningApplications()
  for _, app in ipairs(runningApps) do
    for _, win in ipairs(app:allWindows()) do
      if win:isStandard() then
        win:maximize()
      end
    end
  end
  windowManager:exit()
end)

-- Enter the window manager modal mode
hs.hotkey.bind(config.hyper, ".", function()
  hs.alert.show("Window-Action", 1.5)
  windowManager:enter()
end)
