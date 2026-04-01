local windowsModule = {}

windowsModule.modal = hs.hotkey.modal.new()

-- Hilfsfunktion 1: Bildschirme von links nach rechts sortieren
local function getScreens()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b) return a:frame().x < b:frame().x end)
    return screens
end

-- Hilfsfunktion 2: Den nächsten Monitor relativ zum aktuellen Fenster finden
local function getRelativeScreen(win, step)
    local screens = getScreens()
    local currentScreen = win:screen()
    local currentIndex = 1

    -- Finde heraus, auf welchem Monitor das Fenster gerade ist
    for i, screen in ipairs(screens) do
        if screen == currentScreen then
            currentIndex = i
            break
        end
    end

    -- Berechne den Ziel-Monitor (mit Endlos-Schleife / Wrap-Around)
    local targetIndex = currentIndex + step
    if targetIndex < 1 then targetIndex = #screens end
    if targetIndex > #screens then targetIndex = 1 end

    return screens[targetIndex]
end

-- ==========================================
-- Fenster-Aktionen (Logik)
-- ==========================================

function windowsModule.moveFocusedLeft()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(getRelativeScreen(win, -1)) -- -1 = Ein Monitor nach links
    win:maximize()
  end
  windowsModule.modal:exit()
end

function windowsModule.moveFocusedRight()
  local win = hs.window.focusedWindow()
  if win then
    win:moveToScreen(getRelativeScreen(win, 1))  -- 1 = Ein Monitor nach rechts
    win:maximize()
  end
  windowsModule.modal:exit()
end

function windowsModule.moveAllLeft()
  -- Wir nutzen das aktuelle Fenster als Referenz für die Richtung
  local referenceWin = hs.window.focusedWindow()
  if referenceWin then
    local targetScreen = getRelativeScreen(referenceWin, -1)
    
    -- hs.window.visibleWindows() holt alle nicht-versteckten Fenster aller Apps
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
  -- Wir nutzen das aktuelle Fenster als Referenz für die Richtung
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

-- Modal betreten und verlassen
function windowsModule.enterMode()
  hs.alert.show("Window-Action", 1.5)
  windowsModule.modal:enter()
end

function windowsModule.exitMode()
  windowsModule.modal:exit()
end

return windowsModule