local WindowChooser = {}
WindowChooser.__index = WindowChooser

function WindowChooser.new(registry, options)
  local self = setmetatable({
    registry = registry,
    rows = options.rows or 7,
    callback = nil,
  }, WindowChooser)

  self.chooser = hs.chooser.new(function(choice)
    local callback = self.callback
    self.callback = nil
    if callback and choice then
      callback(self.registry:windowByID(choice.windowID))
    end
  end)
  self.chooser:rows(self.rows)
  self.chooser:searchSubText(false)
  self.chooser:placeholderText("")
  return self
end

function WindowChooser:show(windows, callback)
  local choices = {}
  for _, window in ipairs(windows) do
    local owner = window:application()
    local applicationName = owner and owner:name() or "Window"
    local title = window:title()
    if not title or title == "" then
      title = applicationName
    end
    choices[#choices + 1] = {
      text = applicationName .. " — " .. title,
      windowID = self.registry:windowID(window),
    }
  end

  self.callback = callback
  self.chooser:choices(choices)
  self.chooser:query("")
  self.chooser:show()
end

return WindowChooser
