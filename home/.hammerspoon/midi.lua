local midiModule = {}

-- ==========================================
-- 1. Status und Overlay-Setup
-- ==========================================

local isMuted = false
local lastToggleTime = 0 -- Verhindert, dass Signale sich überschlagen (Debounce)

local screen = hs.screen.primaryScreen():frame()
local canvasWidth = 200
local canvasHeight = 50

local muteOverlay = hs.canvas.new({
    x = (screen.w - canvasWidth) / 2, 
    y = screen.h - canvasHeight - 80, 
    w = canvasWidth, 
    h = canvasHeight
})

muteOverlay:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = {red = 0.9, green = 0.1, blue = 0.1, alpha = 0.85},
    roundedRectRadii = {xRadius = 10, yRadius = 10}
}, {
    type = "text",
    text = "🎙️ MUTED",
    textColor = {white = 1, alpha = 1},
    textSize = 22,
    textAlignment = "center",
    frame = {x = "0%", y = "15%", w = "100%", h = "100%"}
})
muteOverlay:level(hs.canvas.windowLevels.status)

-- ==========================================
-- 2. Zentrale Logik zum Umschalten
-- ==========================================

-- Diese Funktion wird sowohl vom Hotkey als auch vom echten Knopf aufgerufen
local function flipMuteState()
    local now = hs.timer.secondsSinceEpoch()
    
    -- Nur umschalten, wenn der letzte Wechsel mehr als 0.3 Sekunden her ist
    if (now - lastToggleTime) > 0.3 then
        isMuted = not isMuted
        lastToggleTime = now
        
        if isMuted then
            muteOverlay:show()
        else
            muteOverlay:hide()
        end
        print("Mute-Status geändert! Ist jetzt: " .. tostring(isMuted))
    end
end

-- ==========================================
-- 3. MIDI Setup & Hardware-Listener
-- ==========================================

-- Gerät initialisieren (global, wegen Garbage Collection)
rodeMidi = hs.midi.new("RODECaster Pro II")

if rodeMidi then
    rodeMidi:callback(function(object, deviceName, commandType, description, metadata)
        -- HIER IST DIE ÄNDERUNG: Wir prüfen jetzt auch explizit, ob metadata.channel == 0 ist!
        if commandType == "controlChange" and metadata.channel == 0 and metadata.controllerNumber == 27 and metadata.controllerValue == 1 then
            -- Physischer Knopf (nur auf Channel 0) wurde gedrückt -> Hammerspoon Status anpassen
            flipMuteState()
        end
    end)
    print("MIDI Listener bereit. Lausche auf physische Knopfdrücke (nur Channel 0).")
else
    print("Fehler: Rodecaster MIDI ist nicht verbunden.")
end

-- ==========================================
-- 4. Modul-Funktionen (Für die keymapping.lua)
-- ==========================================

function midiModule.toggleRodecasterMute()
    if rodeMidi then
        -- 1. Hardware schalten: Signal an den Rodecaster senden
        rodeMidi:sendCommand("controlChange", { channel = 0, controllerNumber = 27, controllerValue = 1 })
        hs.timer.doAfter(0.1, function()
            rodeMidi:sendCommand("controlChange", { channel = 0, controllerNumber = 27, controllerValue = 0 })
        end)
        
        -- 2. Software schalten: Overlay und Status updaten
        flipMuteState()
    else
        print("Fehler beim Senden: Rodecaster MIDI nicht verbunden.")
    end
end

return midiModule