local layout = {}

local function copyFrame(frame)
  return {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
end

function layout.frames(screenFrame, windowCount)
  if windowCount <= 0 then
    return {}
  end

  if windowCount == 1 then
    return {copyFrame(screenFrame)}
  end

  local leftWidth = math.floor(screenFrame.w / 2)
  return {
    {x = screenFrame.x, y = screenFrame.y, w = leftWidth, h = screenFrame.h},
    {
      x = screenFrame.x + leftWidth,
      y = screenFrame.y,
      w = screenFrame.w - leftWidth,
      h = screenFrame.h,
    },
  }
end

return layout
