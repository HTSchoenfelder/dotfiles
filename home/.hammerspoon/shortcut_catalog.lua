local catalog = {
  entries = {},
  sectionOrder = {
    Applications = 1,
    Windows = 2,
    Navigation = 3,
    Launchers = 4,
    ["Dot mode"] = 5,
    Media = 6,
  },
}

function catalog.add(section, shortcut, description)
  catalog.entries[#catalog.entries + 1] = {
    section = section,
    shortcut = shortcut,
    description = description,
    order = #catalog.entries + 1,
  }
end

function catalog.items()
  local entries = {}
  for index, entry in ipairs(catalog.entries) do
    entries[index] = entry
  end
  table.sort(entries, function(first, second)
    local firstSection = catalog.sectionOrder[first.section] or math.huge
    local secondSection = catalog.sectionOrder[second.section] or math.huge
    if firstSection == secondSection then
      return first.order < second.order
    end
    return firstSection < secondSection
  end)
  return entries
end

function catalog.show()
  if not catalog.chooser then
    catalog.chooser = hs.chooser.new(function() end)
    catalog.chooser:placeholderText("")
    catalog.chooser:searchSubText(false)
    catalog.chooser:rows(12)
  end

  local choices = {}
  for _, entry in ipairs(catalog.items()) do
    choices[#choices + 1] = {
      text = entry.shortcut .. " — " .. entry.description,
    }
  end
  catalog.chooser:choices(choices)
  catalog.chooser:query("")
  catalog.chooser:show()
end

function catalog.start(modifiers)
  catalog.add("Launchers", "MainMod + Shift + R", "Show shortcut catalog")
  local shiftedModifiers = {}
  for _, modifier in ipairs(modifiers) do
    shiftedModifiers[#shiftedModifiers + 1] = modifier
  end
  shiftedModifiers[#shiftedModifiers + 1] = "shift"
  catalog.binding = hs.hotkey.bind(shiftedModifiers, "r", catalog.show)
end

return catalog
