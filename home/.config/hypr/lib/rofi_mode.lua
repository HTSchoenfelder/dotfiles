-- Rofi runs this provider outside the compositor. Only indices cross the IPC boundary.
-- https://github.com/davatorium/rofi/blob/2.0.0/doc/rofi-script.5.markdown
local config_directory = assert(arg[0]:match("^(.*)/lib/rofi_mode.lua$"))
package.path = config_directory .. "/?.lua;" .. package.path
local process = require("lib.process")
local token, rows_path = assert(arg[1]), assert(arg[2])
local instance = assert(os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), "No Hyprland instance")

local function report(callback, value)
    local expression = string.format("%s(%q, %d)", callback, token, value)
    -- Blocking IPC is confined to this short-lived provider, never Hyprland's Lua thread.
    os.execute(process.command({ "hyprctl", "--instance", instance, "eval", expression }) .. " >/dev/null")
end

if os.getenv("ROFI_RETV") == "0" then
    -- Rofi supplies its own PID to script modes, before mapping the layer surface.
    local pid = tonumber(os.getenv("ROFI_OUTSIDE"))
    if not pid or pid <= 1 or pid % 1 ~= 0 then return end
    report("rofi_picker_started", pid)
    local rows = io.open(rows_path, "r")
    if not rows then return end
    io.write("\0prompt\x1f\n\0no-custom\x1ftrue\n\0markup-rows\x1ffalse\n")
    local index = 0
    for label in rows:lines() do
        io.write(label, "\0info\x1f", tostring(index), "\n")
        index = index + 1
    end
    rows:close()
elseif os.getenv("ROFI_RETV") == "1" then
    local index = tonumber(os.getenv("ROFI_INFO"))
    if index and index >= 0 and index % 1 == 0 then
        report("rofi_picker_selected", index)
    end
end
