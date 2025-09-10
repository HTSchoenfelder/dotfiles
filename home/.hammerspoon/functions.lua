-- Behalte deine bestehende objectToJson-Funktion
function objectToJson(obj, maxDepth)
  maxDepth = maxDepth or 5 -- Standard-Rekursionstiefe
  if maxDepth <= 0 then return "[Maximale Tiefe erreicht]" end

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

-- ÄNDERE DIESE FUNKTION
---
--- Inspiziert ein Hammerspoon-Objekt und gibt das Ergebnis als JSON-String zurück.
--- @param objectPath string Der Pfad zum Objekt, z.B. "hs.window.focusedWindow()".
--- @param maxDepth number Die maximale Rekursionstiefe.
--- @return string Ein JSON-String mit der rekursiven Inspektion.
---
function getInspectionJson(objectPath, maxDepth) -- <--- ZWEITEN PARAMETER HINZUGEFÜGT
  require("hs.json")

  local success, obj = pcall(function() return load("return " .. objectPath)() end)
  
  if not success then
    return hs.json.encode({ error = "Error evaluating '" .. objectPath .. "'", message = tostring(obj) })
  end

  -- Rufe die rekursive Funktion mit der übergebenen maxDepth auf
  local jsonData = objectToJson(obj, maxDepth)
  
  return hs.json.encode(jsonData)
end