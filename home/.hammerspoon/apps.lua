local config = require("config")

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

local appWindowManager = hs.hotkey.modal.new()
local pendingApp = nil
local defaultTimer = nil

local function getScreens()
  local screens = hs.screen.allScreens()
  table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
  return screens
end

local function getMainScreen()
  return hs.screen.primaryScreen()
end

local function getSecondaryScreen()
  local primary = hs.screen.primaryScreen()
  for _, screen in ipairs(getScreens()) do
    if screen:id() ~= primary:id() then
      return screen
    end
  end
  return primary
end

local function moveWindow(app, screen, unit)
  if not app or not screen then
    return
  end

  app:activate()
  hs.timer.doAfter(0.1, function()
    local win = app:mainWindow() or app:focusedWindow()
    if not win then
      return
    end

    win:moveToScreen(screen)
    if unit then
      win:moveToUnit(unit)
    else
      win:maximize()
    end
  end)
end

local function applyLayout(layout)
  if not pendingApp then
    return
  end

  if defaultTimer then
    defaultTimer:stop()
    defaultTimer = nil
  end

  local screen = layout.screen()
  moveWindow(pendingApp, screen, layout.unit)
  pendingApp = nil
  appWindowManager:exit()
end

local layouts = {
  mainFull = {screen = getMainScreen},
  secondaryFull = {screen = getSecondaryScreen},
  secondaryLeft = {screen = getSecondaryScreen, unit = {x = 0, y = 0, w = 0.5, h = 1}},
  secondaryRight = {screen = getSecondaryScreen, unit = {x = 0.5, y = 0, w = 0.5, h = 1}},
  mainLeft = {screen = getMainScreen, unit = {x = 0, y = 0, w = 0.5, h = 1}},
  mainRight = {screen = getMainScreen, unit = {x = 0.5, y = 0, w = 0.5, h = 1}},
}

appWindowManager:bind("", "f", function()
  applyLayout(layouts.secondaryFull)
end)

appWindowManager:bind("", "z", function()
  applyLayout(layouts.secondaryLeft)
end)

appWindowManager:bind("", "x", function()
  applyLayout(layouts.secondaryRight)
end)

appWindowManager:bind("", "c", function()
  applyLayout(layouts.mainLeft)
end)

appWindowManager:bind("", "v", function()
  applyLayout(layouts.mainRight)
end)

appWindowManager:bind("", "escape", function()
  if defaultTimer then
    defaultTimer:stop()
    defaultTimer = nil
  end
  pendingApp = nil
  appWindowManager:exit()
end)

-- Create hotkeys to activate applications from the list above
for _, app in ipairs(apps) do
  hs.hotkey.bind(config.hyper, app.key, function()
    config.log.i(app.name)
    local targetApp = hs.application.get(app.name)
    if targetApp then
      pendingApp = targetApp
      if defaultTimer then
        defaultTimer:stop()
      end
      appWindowManager:enter()
      defaultTimer = hs.timer.doAfter(0.2, function()
        applyLayout(layouts.mainFull)
      end)
    else
      hs.notify.new({title = "Hammerspoon", informativeText = app.name .. " not running"}):send()
    end
  end)
end
