local shortcut_catalog = {
    entries = {},
    section_order = {
        Applications = 1,
        Windows = 2,
        Navigation = 3,
        Launchers = 4,
        ["Dot mode"] = 5,
        Media = 6,
    },
}

local key_names = {
    comma = ",",
    period = ".",
    semicolon = ";",
    SHIFT = "Shift",
    CTRL = "Ctrl",
    CONTROL = "Ctrl",
    ALT = "Alt",
    SUPER = "Super",
}

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

function shortcut_catalog.format_key(key)
    local parts = {}
    for part in key:gmatch("[^+]+") do
        local value = trim(part)
        local formatted = key_names[value] or key_names[value:upper()]
        if not formatted and #value == 1 then formatted = value:upper() end
        parts[#parts + 1] = formatted or value
    end
    return table.concat(parts, " + ")
end

function shortcut_catalog.main(key)
    return "MainMod + " .. shortcut_catalog.format_key(key)
end

function shortcut_catalog.dot(key)
    return "MainMod + . → " .. shortcut_catalog.format_key(key)
end

function shortcut_catalog.reset()
    shortcut_catalog.entries = {}
end

function shortcut_catalog.add(section, shortcut, description)
    shortcut_catalog.entries[#shortcut_catalog.entries + 1] = {
        section = section,
        shortcut = shortcut,
        description = description,
        order = #shortcut_catalog.entries + 1,
    }
end

function shortcut_catalog.items()
    local entries = {}
    for index, entry in ipairs(shortcut_catalog.entries) do entries[index] = entry end
    table.sort(entries, function(first, second)
        local first_section = shortcut_catalog.section_order[first.section] or math.huge
        local second_section = shortcut_catalog.section_order[second.section] or math.huge
        if first_section == second_section then return first.order < second.order end
        return first_section < second_section
    end)
    return entries
end

function shortcut_catalog.open(picker)
    local items = {}
    for _, entry in ipairs(shortcut_catalog.items()) do
        items[#items + 1] = {
            label = entry.shortcut .. " — " .. entry.description,
        }
    end
    picker.open(items, { on_select = function() end })
end

return shortcut_catalog
