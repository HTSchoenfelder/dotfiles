local launcher_data = require("lib.launcher_data")
local compositor = require("lib.compositor")
local process = require("lib.process")
local command_launcher = {}

function command_launcher.parse(line)
    -- The last separator leaves shell pipelines intact in the trusted command.
    local command, label = line:match("^(.*)|([^|]+)$")
    if not command or not command:find("%S") or not label:find("%S") then return end
    return { command = command, action = command:match("^lua:([%w_-]+)$"), label = label }
end

function command_launcher.items(path, actions)
    local commands = launcher_data.load(path, command_launcher.parse)
    if not commands then return end
    local items = {}
    for _, command in ipairs(commands) do
        items[#items + 1] = {
            label = command.label,
            action = function()
                if command.action then
                    local action = actions and actions[command.action]
                    if action then action() else compositor.notify("Unknown Lua command: " .. command.action) end
                    return
                end
                -- Only the configured command is executable; Rofi returns a row index.
                process.spawn({ "bash", "-c", command.command })
            end,
        }
    end
    return items
end

function command_launcher.open(picker, path, actions)
    if picker.is_open() then return end
    local items = command_launcher.items(path, actions)
    if not items then return end
    picker.open(items, {
        on_select = function(item) item.action() end,
    })
end

return command_launcher
