local config = require("config")
local DotMode = require("modules.dot_mode")
local MediaControls = require("modules.media_controls")
local ProjectOverlays = require("modules.project_overlays")
local Rodecaster = require("modules.rodecaster")
local TextLauncher = require("modules.text_launcher")
local catalog = require("shortcut_catalog")

local shortcuts = {}

function shortcuts.start(services)
  local rodecaster = Rodecaster.new(config.rodecaster):start()
  shortcuts.rodecasterBinding = hs.hotkey.bind(config.hyper, "\\", function()
    rodecaster:toggleMute()
  end)
  shortcuts.rodecaster = rodecaster
  catalog.add("Media", "MainMod + \\", "Toggle RØDECaster mute")

  local mediaControls = MediaControls.new({commaSelection = services.commaSelection})
  hs.hotkey.bind(config.hyper, "y", function() mediaControls:cycle(1) end, nil,
    function() mediaControls:cycle(1) end)
  local shiftedHyper = {}
  for _, modifier in ipairs(config.hyper) do shiftedHyper[#shiftedHyper + 1] = modifier end
  shiftedHyper[#shiftedHyper + 1] = "shift"
  hs.hotkey.bind(shiftedHyper, "y", function() mediaControls:cycle(-1) end, nil,
    function() mediaControls:cycle(-1) end)
  catalog.add("Media", "MainMod + Y", "Cycle Spotify actions")
  catalog.add("Media", "MainMod + Shift + Y", "Cycle Spotify actions backwards")
  shortcuts.mediaControls = mediaControls

  local overlays = ProjectOverlays.new({
    repository = services.repository,
    gate = services.gate,
    kittyApp = config.paths.kittyApp,
  })
  overlays:start()
  local textLauncher = TextLauncher.new(services.chooserFactory)
  shortcuts.dotMode = DotMode.new({
    modifiers = config.hyper,
    chooserFactory = services.chooserFactory,
    overlays = overlays,
    textLauncher = textLauncher,
    resetLayout = function() services.orchestrator:resetFocused() end,
    screenshotDirectory = config.paths.screenshots,
    emojiPath = config.paths.repository .. "/home/.config/hypr/launcher-data/emoji.txt",
    snippetPath = config.paths.repository .. "/home/.config/hypr/launcher-data/snippets.txt",
  })
  shortcuts.dotMode:start()
end

return shortcuts
