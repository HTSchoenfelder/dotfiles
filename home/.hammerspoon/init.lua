local hyper = {'cmd', 'alt', 'ctrl'}

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

hs.hotkey.bind({"cmd"}, "p", function()
  local frontApp = hs.application.frontmostApplication()
  if frontApp and frontApp:bundleID() == "com.google.Chrome" then
    hs.eventtap.keyStroke({"cmd", "shift"}, "a")
    return true 
  end
  return false 
end)


local windowManager = hs.hotkey.modal.new()

local function getScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
    return screens
end

windowManager:bind("", "h", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[1] then
    win:moveToScreen(screens[1])
  end
  windowManager:exit()
end)

windowManager:bind("", "l", function()
  local win = hs.window.focusedWindow()
  local screens = getScreens()
  if win and screens[2] then
    win:moveToScreen(screens[2])
  elseif win and #screens > 0 then
    win:moveToScreen(screens[#screens])
  end
  windowManager:exit()
end)

windowManager:bind({"shift"}, "h", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  if app and screens[1] then
    for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(screens[1])
    end
  end
  windowManager:exit()
end)

windowManager:bind({"shift"}, "l", function()
  local app = hs.application.frontmostApplication()
  local screens = getScreens()
  if app and screens[2] then
    for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(screens[2])
    end
  elseif app and #screens > 0 then
     for _, win in ipairs(app:allWindows()) do
      win:moveToScreen(screens[#screens])
    end
  end
  windowManager:exit()
end)

windowManager:bind("", "/", function()
  local win = hs.window.focusedWindow()
  if win then
    win:maximize()
  end
  windowManager:exit()
end)

windowManager:bind({"shift"}, "/", function()
  local app = hs.application.frontmostApplication()
  if app then
    for _, win in ipairs(app:allWindows()) do
      win:maximize()
    end
  end
  windowManager:exit()
end)

hs.hotkey.bind(hyper, ".", function()
  hs.alert.show("Fenster-Aktion", 0.5)
  windowManager:enter()
end)

hs.hotkey.bind(hyper, "-", function()
  hs.reload()
end)

hs.notify.new({title = "Hammerspoon", informativeText = "config reloaded"}):send()
