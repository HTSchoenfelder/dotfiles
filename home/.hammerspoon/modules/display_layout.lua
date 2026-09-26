local layout = {}

local function copyFrame(frame)
  return {x = frame.x, y = frame.y, w = frame.w, h = frame.h}
end

function layout.frame(screenFrame, position)
  if position == "full" then
    return copyFrame(screenFrame)
  end

  local leftWidth = math.floor(screenFrame.w / 2)
  if position == "left" then
    return {
      x = screenFrame.x,
      y = screenFrame.y,
      w = leftWidth,
      h = screenFrame.h,
    }
  end
  if position == "right" then
    return {
      x = screenFrame.x + leftWidth,
      y = screenFrame.y,
      w = screenFrame.w - leftWidth,
      h = screenFrame.h,
    }
  end

  error("Unknown window position: " .. tostring(position))
end

return layout
