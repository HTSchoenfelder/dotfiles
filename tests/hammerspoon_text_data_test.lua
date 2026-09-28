-- Run from the repository root: lua tests/hammerspoon_text_data_test.lua
package.path = "home/.hammerspoon/?.lua;home/.hammerspoon/?/init.lua;" .. package.path

local textData = require("modules.text_data")

local emoji = textData.emoji("🫠 melting face")
assert(emoji.text == "🫠" and emoji.label:find("melting face", 1, true))

local snippet = textData.snippet("Viele Grüße\\n\\nHenrik|gh")
assert(snippet.text == "Viele Grüße\n\nHenrik")
assert(snippet.label:find("gh — Viele Grüße  Henrik", 1, true))

assert(textData.emoji("broken") == nil)
assert(textData.snippet("broken") == nil)

print("Hammerspoon text data tests passed")
