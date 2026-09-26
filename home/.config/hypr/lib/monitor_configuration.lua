local compositor = require("lib.compositor")
local monitor_configuration = {}
local configured = {}

function monitor_configuration.apply(specification)
    configured[specification.output] = specification
    hl.monitor(specification)
end

local function connected(name)
    for _, monitor in ipairs(hl.get_monitors({ all = true })) do
        if monitor.name == name then return monitor end
    end
end

function monitor_configuration.toggle(name)
    local monitor = connected(name)
    if not monitor then return end
    if monitor.enabled then
        local enabled = 0
        for _, output in ipairs(hl.get_monitors()) do
            if output.enabled then enabled = enabled + 1 end
        end
        if enabled <= 1 then
            compositor.notify("The last enabled display must remain on.")
            return
        end
    end

    -- Reapply the host's full rule so mode, scale and position survive toggling.
    local specification = {}
    for key, value in pairs(configured[name] or configured[""] or {
        mode = "preferred", position = "auto", scale = "auto",
    }) do specification[key] = value end
    specification.output = name
    specification.disabled = monitor.enabled
    hl.monitor(specification)
end

function monitor_configuration.open(picker)
    if picker.is_open() then return end
    local monitors = hl.get_monitors({ all = true })
    table.sort(monitors, function(first, second) return first.name < second.name end)
    local items = {}
    for _, monitor in ipairs(monitors) do
        items[#items + 1] = {
            name = monitor.name,
            label = (monitor.enabled and "🟢 " or "⚫ ") .. monitor.name
                .. (monitor.enabled and " · enabled" or " · disabled"),
        }
    end
    picker.open(items, { on_select = function(item) monitor_configuration.toggle(item.name) end })
end

return monitor_configuration
