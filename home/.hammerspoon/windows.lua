local windowsModule = {}

windowsModule.modal = hs.hotkey.modal.new()

-- Sort displays from left to right.
local function getScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
    return screens
end

-- Find the next display relative to the current window.
local function getRelativeScreen(win, step)
    local screens = getScreens()
    local currentScreen = win:screen()
    local currentIndex = 1

    -- Find the display that currently contains the window.
    for i, screen in ipairs(screens) do
        if screen == currentScreen then
            currentIndex = i
            break
        end
    end

    -- Wrap around when moving beyond either end of the display list.
    local targetIndex = currentIndex + step
    if targetIndex < 1 then targetIndex = #screens end
    if targetIndex > #screens then targetIndex = 1 end

    return screens[targetIndex]
end

-- Window actions

function windowsModule.moveFocusedLeft()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(getRelativeScreen(win, -1))
    win:maximize()
  end
  windowsModule.modal:exit()
end

function windowsModule.moveFocusedRight()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(getRelativeScreen(win, 1))
    win:maximize()
  end
  windowsModule.modal:exit()
end

function windowsModule.moveAllLeft()
  -- Use the focused window as the directional reference.
  local referenceWin = hs.window.focusedWindow()
  if referenceWin then
    local targetScreen = getRelativeScreen(referenceWin, -1)
    
    -- Move every standard window currently visible across all applications.
    for _, win in ipairs(hs.window.visibleWindows()) do
      if win:isStandard() then
        win:moveToScreen(targetScreen)
        win:maximize()
      end
    end
  end
  windowsModule.modal:exit()
end

function windowsModule.moveAllRight()
  -- Use the focused window as the directional reference.
  local referenceWin = hs.window.focusedWindow()
  if referenceWin then
    local targetScreen = getRelativeScreen(referenceWin, 1)
    
    for _, win in ipairs(hs.window.visibleWindows()) do
      if win:isStandard() then
        win:moveToScreen(targetScreen)
        win:maximize()
      end
    end
  end
  windowsModule.modal:exit()
end

function windowsModule.maximizeFocused()
  local win = hs.window.focusedWindow()
  if win then win:maximize() end
  windowsModule.modal:exit()
end

function windowsModule.maximizeAll()
  local runningApps = hs.application.runningApplications()
  for _, app in ipairs(runningApps) do
    for _, win in ipairs(app:allWindows()) do
      if win:isStandard() then
        win:maximize()
      end
    end
  end
  windowsModule.modal:exit()
end

function windowsModule.enterMode()
  hs.alert.show("Window-Action", 1.5)
  windowsModule.modal:enter()
end

function windowsModule.exitMode()
  windowsModule.modal:exit()
end

return windowsModule
