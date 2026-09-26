local compositor = require("lib.compositor")
local mocha = require("config.catppuccin_mocha")
local dot_mode = {}

function dot_mode.bind(options)
    if options.catalog then
        options.catalog.add("Dot mode", options.catalog.main("period"), "Enter dot mode")
        for _, action in ipairs(options.actions) do
            options.catalog.add("Dot mode", options.catalog.dot(action.key), action.description)
        end
        options.catalog.add("Dot mode", options.catalog.dot("Escape"), "Leave dot mode")
    end

    local notice
    local function dismiss()
        if notice then notice:dismiss(); notice = nil end
    end
    hl.on("keybinds.submap", function(name)
        dismiss()
        if name == "dot" then
            notice = hl.notification.create({
                text = "dot mode", timeout = 1000, icon = "none",
                color = mocha.rgb("green"), font_size = 18,
            })
            notice:pause()
        end
    end)
    hl.on("config.unload", dismiss)

    hl.bind(options.modifier .. " + period", function()
        options.before_enter()
        compositor.dispatch(hl.dsp.submap("dot"))
    end, { dont_inhibit = true, description = "Enter dot mode" })

    hl.define_submap("dot", function()
        for _, action in ipairs(options.actions) do
            hl.bind(action.key, function()
                -- Restore regular bindings and dismiss the notice before opening a tool.
                compositor.dispatch(hl.dsp.submap("reset"))
                action.run()
            end, { ignore_mods = true, dont_inhibit = true, description = action.description })
        end
        hl.bind("Escape", hl.dsp.submap("reset"), {
            ignore_mods = true, dont_inhibit = true, description = "Leave dot mode",
        })
        hl.bind("catchall", hl.dsp.submap("reset"), { ignore_mods = true, dont_inhibit = true })
    end)
end

return dot_mode
