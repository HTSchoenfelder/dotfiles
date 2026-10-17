local compositor = require("lib.compositor")
local mocha = require("config.catppuccin_mocha")
local dot_mode = {}

function dot_mode.bind(options)
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

    local function enter()
        options.before_enter()
        compositor.dispatch(hl.dsp.submap("dot"))
    end
    hl.bind(options.modifier .. " + period", enter,
        { dont_inhibit = true, description = "Enter dot mode" })

    if options.catalog then
        options.catalog.add("Dot mode", options.catalog.main("period"), "Enter dot mode", enter)
        for _, action in ipairs(options.actions) do
            options.catalog.add("Dot mode", options.catalog.dot(action.key), action.description, action.run)
        end
    end

    hl.define_submap("dot", function()
        for _, action in ipairs(options.actions) do
            -- A release binding alone does not consume the preceding key-down.
            -- Swallow it explicitly while the client focus is still unchanged.
            hl.bind(action.key, hl.dsp.no_op(), {
                ignore_mods = true, dont_inhibit = true,
            })
            hl.bind(action.key, function()
                -- Run only after the physical key is up. Focus-changing actions must not
                -- expose the remainder of that key event to the newly focused client.
                compositor.dispatch(hl.dsp.submap("reset"))
                action.run()
            end, {
                release = true, ignore_mods = true, dont_inhibit = true,
                description = action.description,
            })
        end
        hl.bind("Escape", hl.dsp.no_op(), { ignore_mods = true, dont_inhibit = true })
        hl.bind("Escape", hl.dsp.submap("reset"), {
            release = true, ignore_mods = true, dont_inhibit = true,
            description = "Leave dot mode",
        })
        hl.bind("catchall", hl.dsp.no_op(), { ignore_mods = true, dont_inhibit = true })
        hl.bind("catchall", hl.dsp.submap("reset"), {
            release = true, ignore_mods = true, dont_inhibit = true,
        })
    end)
end

return dot_mode
