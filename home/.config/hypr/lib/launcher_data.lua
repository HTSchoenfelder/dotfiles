local compositor = require("lib.compositor")
local launcher_data = {}

function launcher_data.read_items(path, parse_line)
    local file, error_message = io.open(path, "r")
    if not file then return nil, error_message end
    local items = {}
    for line in file:lines() do
        local item = parse_line(line:gsub("\r$", ""))
        if item then items[#items + 1] = item end
    end
    file:close()
    return items
end

function launcher_data.load(path, parse_line)
    local items, error_message = launcher_data.read_items(path, parse_line)
    if not items then
        compositor.notify("Cannot read launcher data: " .. tostring(error_message))
    elseif #items == 0 then
        compositor.notify("No launcher entries.")
    else
        return items
    end
end

return launcher_data
