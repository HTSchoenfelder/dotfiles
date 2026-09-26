local WindowChooser = {}
WindowChooser.__index = WindowChooser

function WindowChooser.new(options)
  local self = setmetatable({
    rows = options.rows or 7,
    callback = nil,
    windowsByID = {},
  }, WindowChooser)

  self.chooser = hs.chooser.new(function(choice)
    local callback = self.callback
    local window = choice and self.windowsByID[choice.windowID] or nil
    self.callback = nil
    self.windowsByID = {}
    if callback and window then
      callback(window)
    end
  end)
  self.chooser:rows(self.rows)
  self.chooser:searchSubText(false)
  self.chooser:placeholderText("")
  return self
end

function WindowChooser:show(windows, callback)
  local choices = {}
  self.windowsByID = {}
  for _, window in ipairs(windows) do
    local windowID = window:id()
    local owner = window:application()
    local applicationName = owner and owner:name() or "Window"
    local title = window:title()
    if not title or title == "" then
      title = applicationName
    end
    self.windowsByID[windowID] = window
    choices[#choices + 1] = {
      text = applicationName .. " — " .. title,
      windowID = windowID,
    }
  end

  self.callback = callback
  self.chooser:choices(choices)
  self.chooser:query("")
  self.chooser:show()
end

return WindowChooser
