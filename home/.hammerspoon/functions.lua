function objectToJson(obj, maxDepth)
  maxDepth = maxDepth or 5
  if maxDepth <= 0 then return "[Maximum depth reached]" end

  local objType = type(obj)

  if objType == "string" or objType == "number" or objType == "boolean" or objType == "nil" then
    return obj
  elseif objType == "function" then
    return "[function]"
  end
  
  local result = {
    _type = objType,
    _value = tostring(obj)
  }

  if objType == "table" then
    result.items = {}
    for key, val in pairs(obj) do
      table.insert(result.items, { key = objectToJson(key, maxDepth - 1), value = objectToJson(val, maxDepth - 1) })
    end
  end

  local mt = getmetatable(obj)
  if mt and mt.__index then
    result._methods = {}
    for key, val in pairs(mt.__index) do
      result._methods[key] = objectToJson(val, maxDepth - 1)
    end
  end

  return result
end

---
--- Inspects a Hammerspoon object and returns the result as JSON.
--- @param objectPath string Expression that resolves to the object.
--- @param maxDepth number Maximum recursion depth.
--- @return string JSON containing the recursive inspection.
---
function getInspectionJson(objectPath, maxDepth)
  require("hs.json")

  local success, obj = pcall(function() return load("return " .. objectPath)() end)
  
  if not success then
    return hs.json.encode({ error = "Error evaluating '" .. objectPath .. "'", message = tostring(obj) })
  end

  local jsonData = objectToJson(obj, maxDepth)
  
  return hs.json.encode(jsonData)
end
