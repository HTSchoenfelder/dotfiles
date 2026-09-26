local launcher_data = require("lib.launcher_data")
local process = require("lib.process")
local command_launcher = {}

function command_launcher.parse(line)
    -- The last separator leaves shell pipelines intact in the trusted command.
    local command, label = line:match("^(.*)|([^|]+)$")
    if not command or not command:find("%S") or not label:find("%S") then return end
    return { command = command, label = label }
end

function command_launcher.open(picker, path)
    if picker.is_open() then return end
    local items = launcher_data.load(path, command_launcher.parse)
    if not items then return end
    picker.open(items, {
        on_select = function(item)
            -- Only the configured command is executable; Rofi returns a row index.
            process.spawn({ "bash", "-c", item.command })
        end,
    })
end

return command_launcher
