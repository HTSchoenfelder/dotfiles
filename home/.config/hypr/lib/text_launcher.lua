local compositor = require("lib.compositor")
local process = require("lib.process")
local text_launcher = {}

function text_launcher.emoji(line)
    local emoji = line:match("^(%S+)")
    if emoji then return { label = line, text = emoji } end
end

function text_launcher.snippet(line)
    local text, alias = line:match("^(.-)|(.+)$")
    if not text or text == "" then return nil end
    local escapes = { n = "\n", t = "\t", ["\\"] = "\\" }
    return {
        label = text .. " | " .. alias,
        text = text:gsub("\\([nt\\])", escapes),
    }
end

function text_launcher.read_items(path, parse_line)
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

function text_launcher.insert(text)
    process.spawn({ "wtype", "--", text })
end

function text_launcher.open(picker, path, parse_line)
    if picker.is_open() then return end
    local origin = hl.get_active_window()
    if not origin then return end
    local items, error_message = text_launcher.read_items(path, parse_line)
    if not items then
        compositor.notify("Cannot read launcher data: " .. tostring(error_message))
        return
    end
    if #items == 0 then
        compositor.notify("No launcher entries.")
        return
    end
    picker.open(items, {
        is_current = function()
            local active = hl.get_active_window()
            return origin.mapped and active ~= nil and active.address == origin.address
        end,
        on_select = function(item) text_launcher.insert(item.text) end,
    })
end

return text_launcher
