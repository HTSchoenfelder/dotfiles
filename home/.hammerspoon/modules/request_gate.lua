local RequestGate = {}
RequestGate.__index = RequestGate

function RequestGate.new()
  return setmetatable({generation = 0}, RequestGate)
end

function RequestGate:next()
  self.generation = self.generation + 1
  return self.generation
end

function RequestGate:current()
  return self.generation
end

function RequestGate:isCurrent(generation)
  return generation == self.generation
end

return RequestGate
