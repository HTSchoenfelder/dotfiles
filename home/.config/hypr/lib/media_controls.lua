local process = require("lib.process")
local media_controls = {}

function media_controls.control(player, command)
    process.spawn({ "playerctl", "--player", player, command })
end

function media_controls.cycle(picker, options)
    if picker.is_open() then return end
    local items = {
        { label = "Play/Pause", command = "play-pause" },
        { label = "Next", command = "next" },
        { label = "Previous", command = "previous" },
        { label = "Spotify" },
    }
    picker.open(items, {
        cycle_key = options.key,
        initial_index = options.direction > 0 and 1 or #items,
        on_select = function(item)
            if item.command then
                media_controls.control(options.player, item.command)
            else
                options.open_spotify()
            end
        end,
    })
end

return media_controls
