local process = require("lib.process")
local media_controls = {}
local now_playing = assert(debug.getinfo(1, "S").source:match("^@(.*)/media_controls.lua$"))
    .. "/now_playing.lua"

function media_controls.control(player, command)
    process.spawn({ "playerctl", "--player", player, command })
end

function media_controls.show_now_playing(player)
    process.spawn({ "lua", now_playing, player })
end

function media_controls.cycle(picker, options)
    if picker.is_open() then return end
    local items = {
        { label = "Play/Pause", command = "play-pause" },
        { label = "Spotify", open = true },
        { label = "Next", command = "next" },
        { label = "Previous", command = "previous" },
        { label = "Now Playing", notify = true },
    }
    picker.open(items, {
        cycle_key = options.key,
        initial_index = options.direction > 0 and 1 or #items,
        on_select = function(item)
            if item.open then
                options.open()
            elseif item.notify then
                media_controls.show_now_playing(options.player)
            else
                media_controls.control(options.player, item.command)
            end
        end,
    })
end

return media_controls
