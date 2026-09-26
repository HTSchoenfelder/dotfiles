-- Hyprland 0.55+ Lua configuration. The host monitor symlink is created by setup-nixos.sh.
local config_directory = assert(debug.getinfo(1, "S").source:match("^@(.*/)"))
package.path = config_directory .. "?.lua;" .. package.path

require("config.monitor")
require("config.environment")
require("config.input")
require("config.appearance")
require("config.window_rules")
require("config.session")
require("config.keybindings")
require("config.hardware_keys")
