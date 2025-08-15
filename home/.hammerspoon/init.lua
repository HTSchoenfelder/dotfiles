-- Define a global "hyper" key as Cmd+Alt+Ctrl
local hyper = {'cmd', 'alt', 'ctrl'}

-- Define a list of applications to be launched with hotkeys
local apps = {
  {key = "j", name = "kitty"},
  {key = "k", name = "Code"},
  {key = "l", name = "Chrome"},
  {key = "u", name = "Google Chat"},
  {key = "i", name = "Gmail"},
  {key = ";", name = "Obsidian"},
  {key = "o", name = "KeePassXC"},
  {key = "p", name = "Spotify"},
}

-- Create hotkeys to activate applications from the list above
for _, app in ipairs(apps) do
  hs.hotkey.bind(hyper, app.key, function()
    local targetApp = hs.application.get(app.name)
    if targetApp then
      targetApp:activate()
    else
      hs.notify.new({title = "Hammerspoon", informativeText = app.name .. " not running"}):send()
    end
  end)
end

-- App-specific hotkeys for Chrome, managed by an application watcher
local chromeHotkeys = {}
local appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    if eventType == hs.application.watcher.activated then
        if appObject:bundleID() == "com.google.Chrome" then
            -- Create hotkeys only if they don't already exist
            if next(chromeHotkeys) == nil then
                chromeHotkeys.p = hs.hotkey.bind({"cmd"}, "p", function() hs.eventtap.keyStroke({"cmd", "shift"}, "a") end) -- Search tabs
                chromeHotkeys.j = hs.hotkey.bind({"cmd"}, "j", function() hs.eventtap.keyStroke({"ctrl", "shift"}, "tab") end) -- Previous tab
                chromeHotkeys.k = hs.hotkey.bind({"cmd"}, "k", function() hs.eventtap.keyStroke({"ctrl"}, "tab") end) -- Next tab
                chromeHotkeys.h = hs.hotkey.bind({"cmd"}, "h", function() hs.eventtap.keyStroke({"cmd"}, "[") end) -- History back
                chromeHotkeys.l = hs.hotkey.bind({"cmd"}, "l", function() hs.eventtap.keyStroke({"cmd"}, "]") end) -- History forward
            end
        else
            -- If another app is activated, delete the Chrome hotkeys to avoid conflicts
            if next(chromeHotkeys) ~= nil then
                for key, hotkey in pairs(chromeHotkeys) do
                    hotkey:delete()
                end
                chromeHotkeys = {}
            end
        end
    end
end)
appWatcher:start()


-- Modal hotkey for window management
local windowManager = hs.hotkey.modal.new()

-- Helper function to get screens, sorted from left to right
local function getScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
    return screens
end

-- Move focused window to left screen and maximize
windowManager:bind("", "h", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[1] then
    win:moveToScreen(screens[1])
    win:maximize()
  end
  windowManager:exit()
end)

-- Move focused window to right screen and maximize
windowManager:bind("", "l", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[2] then
    win:moveToScreen(screens[2])
    win:maximize()
  elseif win and #screens > 0 then
    win:moveToScreen(screens[#screens])
    win:maximize()
  end
  windowManager:exit()
end)

-- Move all windows of the frontmost app to the left screen and maximize
windowManager:bind({"shift"}, "h", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  if app and screens[1] then
    for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(screens[1])
      win:maximize()
    end
  end
  windowManager:exit()
end)

-- Move all windows of the frontmost app to the right screen and maximize
windowManager:bind({"shift"}, "l", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  local targetScreen = screens[2] or screens[#screens]
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
hs.hotkey.bind(hyper, ".", function()
  hs.alert.show("Fenster-Aktion", 0.5)
  windowManager:enter()
end)

-- Reload Hammerspoon config
hs.hotkey.bind(hyper, "-", function()
  hs.reload()
end)

-- Notify that the config has been loaded
hs.notify.new({title = "Hammerspoon", informativeText = "config reloaded"}):send()
