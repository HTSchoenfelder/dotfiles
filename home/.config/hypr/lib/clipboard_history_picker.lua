-- Runs outside Hyprland's Lua thread. It may block while Rofi is open.
local config_directory = assert(arg[0]:match("^(.*)/lib/clipboard_history_picker.lua$"))
package.path = config_directory .. "/?.lua;" .. package.path

local process = require("lib.process")
local history_path = assert(arg[1], "Clipse history path is required")

local function copy_file(source_path, destination_path)
    local source = io.open(source_path, "rb")
    if not source then return false end
    local destination = io.open(destination_path, "wb")
    if not destination then source:close(); return false end
    while true do
        local chunk = source:read(65536)
        if not chunk then break end
        destination:write(chunk)
    end
    source:close()
    destination:close()
    return true
end

local function command_output(arguments, input_path)
    local command = process.command(arguments)
    if input_path then command = command .. " < " .. process.command({ input_path }) end
    local pipe = io.popen(command, "r")
    if not pipe then return nil end
    local output = pipe:read("*a")
    local ok = pipe:close()
    if not ok then return nil end
    return output
end

local function write_command(arguments, output_path)
    return os.execute(process.command(arguments) .. " > " .. process.command({ output_path })) == true
end

local snapshot_path = os.tmpname()
local rows_path = os.tmpname()
local payload_path

local function cleanup()
    os.remove(snapshot_path)
    os.remove(rows_path)
    if payload_path then os.remove(payload_path) end
end

if not copy_file(history_path, snapshot_path) then cleanup(); return end

local row_filter = [[
    .clipboardHistory[].value |
    gsub("[\u0000-\u001f\u007f]"; " ") |
    if length > 160 then .[0:157] + "..." else . end
]]
if not write_command({ "jq", "-r", row_filter, snapshot_path }, rows_path) then cleanup(); return end

local rows = io.open(rows_path, "rb")
if not rows then cleanup(); return end
local has_rows = rows:read(1) ~= nil
rows:close()
if not has_rows then cleanup(); return end

local selected = command_output({
    "rofi", "-dmenu", "-format", "i", "-no-custom", "-no-sort", "-i", "-p", "",
}, rows_path)
if not selected then cleanup(); return end
local index = tonumber(selected:match("^%s*(%d+)%s*$"))
if not index then cleanup(); return end

local jq_index = tostring(index)
local file_path = command_output({
    "jq", "-r", "--argjson", "index", jq_index,
    ".clipboardHistory[$index].filePath", snapshot_path,
})
if not file_path then cleanup(); return end
file_path = file_path:gsub("%s+$", "")

local source_path = file_path
local mime_type = "image/png"
if file_path == "null" or file_path == "" then
    payload_path = os.tmpname()
    source_path = payload_path
    mime_type = "text/plain;charset=utf-8"
    if not write_command({
        "jq", "-j", "--argjson", "index", jq_index,
        ".clipboardHistory[$index].value", snapshot_path,
    }, payload_path) then cleanup(); return end
end

local copied = os.execute(process.command({ "wl-copy", "--type", mime_type })
    .. " < " .. process.command({ source_path })) == true
if copied then
    os.execute(process.command({ "wtype", "-s", "50", "-M", "ctrl", "-k", "v", "-m", "ctrl" }))
end
cleanup()
