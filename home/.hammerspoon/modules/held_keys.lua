local HeldKeys = {}
HeldKeys.__index = HeldKeys

function HeldKeys.new(modifiers)
  return setmetatable({modifiers = modifiers, bindings = {}, held = {}}, HeldKeys)
end

function HeldKeys:track(key)
  local normalized = key:lower()
  self.bindings[#self.bindings + 1] = hs.hotkey.bind(
    self.modifiers,
    normalized,
    function() self.held[normalized] = true end,
    function() self.held[normalized] = false end
  )
end

function HeldKeys:isDown(key)
  return self.held[key:lower()] == true
end

return HeldKeys
