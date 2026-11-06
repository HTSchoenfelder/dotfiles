-- This short-lived process keeps MPRIS and cover downloads outside Hyprland's Lua thread.
local config_directory = assert(arg[0]:match("^(.*)/lib/now_playing.lua$"))
package.path = config_directory .. "/?.lua;" .. package.path
local process = require("lib.process")
local player = assert(arg[1], "A player is required")

local function metadata(field)
    local command = process.command({ "timeout", "1s", "playerctl", "--player", player,
        "metadata", "--format", "{{" .. field .. "}}" }) .. " 2>/dev/null"
    local output = io.popen(command)
    if not output then return end
    local value = output:read("*l")
    local success = output:close()
    if success and value and value:match("%S") then return value end
end

local title = metadata("title")
if not title then return end
local artist = metadata("artist")
local art_url = metadata("mpris:artUrl")
local icon = "spotify"
local cover
if art_url and art_url:match("^https://") then
    cover = os.tmpname()
    local download = process.command({ "curl", "-fsSL", "--max-time", "2", "--output", cover,
        "--", art_url }) .. " 2>/dev/null"
    if os.execute(download) then icon = cover end
end

local body = artist and "\n" .. artist or ""
os.execute(process.command({ "notify-send", "-a", "Spotify", "-t", "2000", "-i", icon,
    "--", title, body }) .. " >/dev/null 2>&1")
if cover then os.remove(cover) end
