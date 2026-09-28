local textData = {}

function textData.emoji(line)
  local symbol, description = line:match("^(%S+)%s+(.+)$")
  if not symbol then return nil end
  return {text = symbol, label = symbol .. " — " .. description}
end

function textData.snippet(line)
  local value, shortcut = line:match("^(.-)|([^|]+)$")
  if not value then return nil end
  value = value:gsub("\\n", "\n")
  return {text = value, label = shortcut .. " — " .. value:gsub("\n", " ")}
end

function textData.read(path, parser)
  local file, openError = io.open(path, "r")
  if not file then return nil, openError end
  local items = {}
  for line in file:lines() do
    local item = parser(line:gsub("\r$", ""))
    if item then items[#items + 1] = item end
  end
  file:close()
  return items
end

return textData
