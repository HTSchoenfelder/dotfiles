local midiModule = {}

-- Status and overlay setup

local isMuted = false
local lastToggleTime = 0

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

-- Shared by the keyboard shortcut and the physical button.
local function flipMuteState()
    local now = hs.timer.secondsSinceEpoch()
    
    -- Debounce duplicate signals from the device.
    if (now - lastToggleTime) > 0.3 then
        isMuted = not isMuted
        lastToggleTime = now
        
        if isMuted then
            muteOverlay:show()
        else
            muteOverlay:hide()
        end
        print("Mute state changed: " .. tostring(isMuted))
    end
end

-- Keep the MIDI object global so it survives garbage collection.
rodeMidi = hs.midi.new("RODECaster Pro II")

if rodeMidi then
    rodeMidi:callback(function(object, deviceName, commandType, description, metadata)
        if commandType == "controlChange" and metadata.channel == 0 and metadata.controllerNumber == 27 and metadata.controllerValue == 1 then
            -- Mirror physical button presses from channel 0 in Hammerspoon.
            flipMuteState()
        end
    end)
    print("MIDI listener ready for physical button presses on channel 0.")
else
    print("Rodecaster MIDI is not connected.")
end

function midiModule.toggleRodecasterMute()
    if rodeMidi then
        -- Send the button press and release to the Rodecaster.
        rodeMidi:sendCommand("controlChange", { channel = 0, controllerNumber = 27, controllerValue = 1 })
        hs.timer.doAfter(0.1, function()
            rodeMidi:sendCommand("controlChange", { channel = 0, controllerNumber = 27, controllerValue = 0 })
        end)
        
        -- Keep the local state and overlay synchronized.
        flipMuteState()
    else
        print("Cannot send mute command: Rodecaster MIDI is not connected.")
    end
end

return midiModule
