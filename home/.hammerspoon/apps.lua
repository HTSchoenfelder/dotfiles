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

-- Create hotkeys to activate applications from the list above
for _, app in ipairs(apps) do
  hs.hotkey.bind(config.hyper, app.key, function()
    config.log.i(app.name)
    local targetApp = hs.application.get(app.name)
    if targetApp then
      targetApp:activate()
    else
      hs.notify.new({title = "Hammerspoon", informativeText = app.name .. " not running"}):send()
    end
  end)
end