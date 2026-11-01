local MediaControls = {}
MediaControls.__index = MediaControls

local actions = {
  {
    id = "play_pause",
    text = "Play/Pause",
    mediaKey = "PLAY",
  },
  {
    id = "next",
    text = "Next",
    mediaKey = "NEXT",
  },
  {
    id = "previous",
    text = "Previous",
    mediaKey = "PREVIOUS",
  },
  {
    id = "spotify",
    text = "Spotify",
    open = true,
  },
}

local function sendMediaKey(key)
  hs.eventtap.event.newSystemKeyEvent(key, true):post()
  hs.eventtap.event.newSystemKeyEvent(key, false):post()
end

function MediaControls.new(options)
  options = options or {}
  return setmetatable({
    commaSelection = assert(options.commaSelection, "Comma Selection is required"),
    openSpotify = assert(options.openSpotify, "Spotify opener is required"),
    sendMediaKey = options.sendMediaKey or sendMediaKey,
  }, MediaControls)
end

function MediaControls:execute(action)
  if not action then return end
  if action.open then self.openSpotify(); return end
  if action.mediaKey then self.sendMediaKey(action.mediaKey) end
end

function MediaControls:cycle(direction)
  self.commaSelection:cycle("media", direction, {
    currentID = direction > 0 and actions[#actions].id or actions[1].id,
    load = function(done) done(actions) end,
    onSelect = function(action) self:execute(action) end,
  })
end

MediaControls.actions = actions

return MediaControls
