local compositor = require("lib.compositor")
local shortcut_forwarding = {}

function shortcut_forwarding.forward(settings, key)
    local window = hl.get_active_window()
    if not window or not window.mapped then return end
    local application = settings.applications[window.class]
    local shortcut = application and application[key] or { mods = settings.modifier, key = key }
    compositor.dispatch(hl.dsp.send_shortcut({
        mods = shortcut.mods,
        key = shortcut.key,
        window = window,
    }))
end

function shortcut_forwarding.bind(settings, catalog)
    for _, key in ipairs(settings.keys) do
        hl.bind(settings.modifier .. " + " .. key, function()
            shortcut_forwarding.forward(settings, key)
        end, { description = "Forward application shortcut " .. key })
        if catalog then
            catalog.add(
                "Applications",
                catalog.format_key(settings.modifier .. " + " .. key),
                "Forward application shortcut"
            )
        end
    end
end

return shortcut_forwarding
