local planner = {}

local function move(windowID, workspace)
  return {"move-node-to-workspace", "--window-id", tostring(windowID), tostring(workspace)}
end

local function tiledWindows(windows, targetID)
  local result = {}
  for _, window in ipairs(windows or {}) do
    if window.tiled ~= false and window.id ~= targetID then
      result[#result + 1] = window
    end
  end
  return result
end

function planner.activation(target, destination, windows, parking, mode)
  assert(target and target.id, "Target window is required")
  destination = tostring(destination)
  parking = tostring(parking)
  local existing = tiledWindows(windows, target.id)
  local commands = {}

  if mode == "stack" then
    if target.workspace == destination and destination ~= parking then
      commands[#commands + 1] = move(target.id, parking)
    end
    commands[#commands + 1] = move(target.id, destination)
    commands[#commands + 1] = {"layout", "--window-id", tostring(target.id), "tiling"}
    commands[#commands + 1] = {"flatten-workspace-tree", "--workspace", destination}
    commands[#commands + 1] = {"layout", "--workspace", destination, "--root", "h_tiles"}

    local stack = {}
    for index = 2, #existing do stack[#stack + 1] = existing[index] end
    stack[#stack + 1] = target
    if #stack >= 2 then
      for index = 1, #stack - 1 do
        commands[#commands + 1] = {
          "join-with", "--window-id", tostring(stack[index].id), "right",
        }
      end
      commands[#commands + 1] = {
        "layout", "--window-id", tostring(stack[1].id), "v_tiles",
      }
    end
  else
    commands[#commands + 1] = move(target.id, destination)
    commands[#commands + 1] = {"layout", "--window-id", tostring(target.id), "tiling"}
    if destination ~= parking then
      for _, window in ipairs(existing) do
        commands[#commands + 1] = move(window.id, parking)
      end
    end
    commands[#commands + 1] = {"flatten-workspace-tree", "--workspace", destination}
    commands[#commands + 1] = {"layout", "--workspace", destination, "--root", "h_tiles"}
  end

  commands[#commands + 1] = {"balance-sizes", "--workspace", destination}
  commands[#commands + 1] = {"focus", "--window-id", tostring(target.id)}
  return commands
end

return planner
