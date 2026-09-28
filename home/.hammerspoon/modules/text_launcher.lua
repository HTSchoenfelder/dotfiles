local textData = require("modules.text_data")

local TextLauncher = {}
TextLauncher.__index = TextLauncher

function TextLauncher.new(chooserFactory)
  return setmetatable({chooserFactory = chooserFactory}, TextLauncher)
end

function TextLauncher:insert(text, origin)
  local clipboard = hs.pasteboard.readAllData()
  if origin then origin:focus() end
  hs.timer.doAfter(0.08, function()
    hs.pasteboard.setContents(text)
    hs.eventtap.keyStroke({"cmd"}, "v", 0)
    hs.timer.doAfter(0.2, function()
      hs.pasteboard.clearContents()
      if clipboard and next(clipboard) then hs.pasteboard.writeAllData(clipboard) end
    end)
  end)
end

function TextLauncher:open(path, parser)
  local origin = hs.window.focusedWindow()
  local items, readError = textData.read(path, parser)
  if not items then
    hs.notify.new({title = "Text launcher", informativeText = tostring(readError)}):send()
    return
  end
  local choices = {}
  for _, item in ipairs(items) do
    choices[#choices + 1] = {text = item.label, value = item.text}
  end
  local chooser = self.chooserFactory()
  chooser:show(choices, function(selected)
    if selected then self:insert(selected.value, origin) end
  end, origin and origin:screen())
end

TextLauncher.data = textData

return TextLauncher
