local planner = {}

local function inset(frame, gap)
  return {
    x = frame.x + gap,
    y = frame.y + gap,
    w = math.max(1, frame.w - gap * 2),
    h = math.max(1, frame.h - gap * 2),
  }
end

function planner.frames(screenFrame, count, gap)
  if count <= 0 then return {} end
  gap = gap or 0
  local area = inset(screenFrame, gap)
  if count == 1 then return {area} end

  local inner = gap
  local leftWidth = math.floor((area.w - inner) / 2)
  local rightX = area.x + leftWidth + inner
  local rightWidth = area.w - leftWidth - inner
  local frames = {{x = area.x, y = area.y, w = leftWidth, h = area.h}}
  if count == 2 then
    frames[2] = {x = rightX, y = area.y, w = rightWidth, h = area.h}
    return frames
  end

  local stackCount = count - 1
  local stackHeight = math.floor((area.h - inner * (stackCount - 1)) / stackCount)
  local y = area.y
  for index = 2, count do
    local height = index == count and area.y + area.h - y or stackHeight
    frames[index] = {x = rightX, y = y, w = rightWidth, h = height}
    y = y + height + inner
  end
  return frames
end

return planner
