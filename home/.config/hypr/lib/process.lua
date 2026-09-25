local process = {}

function process.command(arguments)
    local quoted = {}
    for index, argument in ipairs(arguments) do
        local value = tostring(argument)
        assert(not value:find("\0", 1, true), "Command arguments cannot contain NUL bytes")
        quoted[index] = "'" .. value:gsub("'", "'\\''") .. "'"
    end
    assert(#quoted > 0, "A command is required")
    return table.concat(quoted, " ")
end

function process.spawn(arguments, rules)
    hl.exec_cmd("exec " .. process.command(arguments), rules)
end

function process.terminate(pid)
    if type(pid) == "number" and pid > 1 and pid % 1 == 0 then
        process.spawn({ "kill", "-TERM", tostring(pid) })
    end
end

return process
