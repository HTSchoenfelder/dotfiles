local config = require("config")
local DotMode = require("modules.dot_mode")
local ProjectOverlays = require("modules.project_overlays")
local TextLauncher = require("modules.text_launcher")
local catalog = require("shortcut_catalog")
local midi = require("midi")

local shortcuts = {}

function shortcuts.start(services, applications)
  midi:start()
  shortcuts.midiBinding = hs.hotkey.bind({"alt", "ctrl", "cmd", "shift"}, "m", function()
    midi:toggleMute()
  end)
  catalog.add("Media", "MainMod + Shift + M", "Toggle RØDECaster mute")

  local overlays = ProjectOverlays.new({
    client = services.client,
    repository = services.repository,
    gate = services.gate,
    workspaces = services.workspaceNames,
    kittyApp = config.paths.kittyApp,
  })
  overlays:start()
  local textLauncher = TextLauncher.new(services.chooserFactory)
  local function resetWorkspaces()
    services.client:focusWorkspace(services.workspaceNames.terminal, function(_, requestError)
      if requestError then require("modules.layout_orchestrator").report(requestError); return end
      applications:activate(require("apps")[1], "single", false)
    end, "workspace_reset")
  end
  shortcuts.dotMode = DotMode.new({
    modifiers = config.hyper,
    chooserFactory = services.chooserFactory,
    overlays = overlays,
    textLauncher = textLauncher,
    windows = services.windows,
    resetWorkspaces = resetWorkspaces,
    emojiPath = config.paths.repository .. "/home/.config/hypr/launcher-data/emoji.txt",
    snippetPath = config.paths.repository .. "/home/.config/hypr/launcher-data/snippets.txt",
  })
  shortcuts.dotMode:start()
end

return shortcuts
