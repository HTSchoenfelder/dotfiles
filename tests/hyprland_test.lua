-- Run from the repository root: lua tests/hyprland_test.lua
package.path = "home/.config/hypr/?.lua;tests/?.lua;" .. package.path
local support = require("hyprland_support")
local windows = require("lib.window_navigation")
local text_launcher = require("lib.text_launcher")
local process = require("lib.process")
local modifier = "SUPER + CTRL + ALT + "
local passed = 0

local function test(name, callback)
    local session = support.session()
    local ok, error_message = xpcall(function() callback(session) end, debug.traceback)
    session.close()
    assert(ok, name .. ": " .. tostring(error_message))
    passed = passed + 1
end

test("direct navigation selects the most recent instance and parks other windows", function(session)
    local old = session.add("code", 2, 4)
    local recent = session.add("Code", 10, 1)
    local current = session.add("kitty", 1, 0)
    session.focus(current)
    session.press(modifier .. "K")
    assert(session.focused == recent and recent.workspace.id == 1)
    assert(current.workspace.id == 10 and old.workspace.id == 2)
end)

test("stack navigation preserves existing windows and clears fullscreen", function(session)
    local master = session.add("kitty", 1)
    local slave = session.add("google-chrome", 1)
    local code = session.add("code", 10)
    master.fullscreen = 2
    master.workspace.fullscreen_window = master
    session.focus(master)
    session.held.f = true
    session.press(modifier .. "K")
    assert(master.workspace.id == 1 and slave.workspace.id == 1 and code.workspace.id == 1)
    assert(master.fullscreen == 0 and session.focused == code)
end)

test("parking workspace never parks its own windows", function(session)
    local code = session.add("code", 10)
    local other = session.add("kitty", 10)
    session.focus(other)
    session.press(modifier .. "K")
    assert(code.workspace.id == 10 and other.workspace.id == 10)
end)

test("navigation detaches groups and unpins floating windows", function(session)
    local code = session.add("code", 2)
    code.floating, code.pinned, code.fullscreen = true, true, 2
    code.group = { remove = function(_, window) window.group = nil end }
    session.press(modifier .. "K")
    assert(not code.group and not code.floating and not code.pinned and code.fullscreen == 0)
end)

test("an instance picker opens even for a single window", function(session)
    local code = session.add("code", 2)
    session.held.a = true
    session.press(modifier .. "K")
    assert(session.picker_request() and code.workspace.id == 2)
    session.choose(0)
    assert(session.focused == code and code.workspace.id == 1)
end)

test("P uses MRU ordering and duplicate titles keep distinct identities", function(session)
    local older = session.add("code", 2, 3)
    local recent = session.add("code", 10, 1)
    session.add("kitty", 1, -1)
    session.press(modifier .. "P")
    session.choose(1)
    assert(session.focused == older and recent.workspace.id == 10)
end)

test("closed and reclassified windows cannot be selected", function(session)
    local code = session.add("code", 2)
    session.held.a = true
    session.press(modifier .. "K")
    code.class = "other"
    session.choose(0)
    assert(session.focused == nil)
    session.press(modifier .. "P")
    code.mapped = false
    session.choose(0)
    assert(session.focused == nil)
end)

test("repeated requests start only one process and use the latest stack preference", function(session)
    local master = session.add("kitty", 1)
    session.focus(master)
    session.press(modifier .. "K")
    session.held.f = true
    session.press(modifier .. "K")
    assert(#session.commands == 1 and session.commands[1].arguments[1] == "code")
    assert(session.commands[1].rules.no_initial_focus)
    local code = session.add("code", 1)
    session.emit("window.open", code)
    session.flush()
    assert(session.focused == code and master.workspace.id == 1)
end)

test("a superseded launch is parked without stealing focus", function(session)
    session.press(modifier .. "K")
    local chrome = session.add("google-chrome", 1)
    session.press(modifier .. "L")
    local code = session.add("code", 1)
    session.emit("window.class", code)
    session.flush()
    assert(code.workspace.id == 10 and session.focused == chrome)
end)

test("a workspace switch invalidates a pending launch even after returning", function(session)
    session.press(modifier .. "K")
    session.press(modifier .. "H")
    session.press(modifier .. "H")
    local code = session.add("code", 1)
    session.emit("window.open", code)
    session.flush()
    assert(code.workspace.id == 10 and session.focused == nil)
end)

test("launch timeout allows retry and reports failure", function(session)
    session.press(modifier .. "K")
    session.flush(15000)
    assert(#session.notices == 1)
    session.press(modifier .. "K")
    assert(#session.commands == 2)
end)

test("position rotation retains the focused layout slot", function(session)
    local first, second, third = session.add("a", 1), session.add("b", 1), session.add("c", 1)
    session.layout_order = { first, second, third }
    session.focus(second)
    session.press(modifier .. "N")
    assert(session.focused == third and session.layout_order[2] == third)
end)

test("quick comma release selects the previous window without mapping Rofi", function(session)
    local current = session.add("kitty", 1, 0)
    local previous = session.add("code", 10, 1)
    session.focus(current)
    session.press(modifier .. "comma")
    session.press("Alt_L")
    assert(session.focused == previous)
end)

test("mapped cycles defer actions until the Rofi layer has closed", function(session)
    session.focus(session.add("kitty", 1, 0))
    local code = session.add("code", 10, 1)
    session.press(modifier .. "comma")
    local request = session.map_picker()
    assert(not session.bindings[modifier .. "Y"].enabled)
    rofi_picker_selected(request.token, 1)
    assert(session.focused ~= code)
    session.emit("layer.closed", { pid = 5000 })
    assert(session.bindings[modifier .. "Y"].enabled)
    session.flush()
    assert(session.focused == code)
end)

test("F can change an open window selection to stack mode", function(session)
    local master = session.add("kitty", 1, 0)
    session.focus(master)
    session.add("code", 10, 1)
    session.press(modifier .. "comma")
    session.press(modifier .. "F")
    session.choose(1)
    assert(master.workspace.id == 1)
end)

test("Escape cancels and stale callbacks cannot select a later picker", function(session)
    session.add("kitty", 1)
    session.press(modifier .. "comma")
    local stale = session.map_picker()
    session.press(modifier .. "Escape")
    session.press(modifier .. "P")
    rofi_picker_selected(stale.token, 0)
    session.emit("layer.closed", { pid = 5000 })
    session.flush()
    assert(session.focused == nil)
    assert(not io.open(stale.path))
end)

test("malformed and out-of-range selections do nothing", function(session)
    session.add("kitty", 1)
    for _, index in ipairs({ -1, 0.5, "0", 10 }) do
        session.press(modifier .. "P")
        session.choose(index)
        assert(session.focused == nil)
    end
end)

test("launcher startup failure cleans up and restores keybindings", function(session)
    session.add("kitty", 1)
    session.press(modifier .. "comma")
    local request = session.picker_request()
    session.flush(3000)
    assert(not io.open(request.path) and #session.notices == 1)
    assert(session.bindings[modifier .. "comma"].enabled)
end)

test("a new picker invalidates a result waiting for keyboard focus restoration", function(session)
    session.press(modifier .. "Y")
    local request = session.map_picker()
    rofi_picker_selected(request.token, 0)
    session.emit("layer.closed", { pid = 5000 })
    session.focus(session.add("code", 1))
    session.press(modifier .. "E")
    session.flush()
    for _, command in ipairs(session.commands) do assert(command.arguments[1] ~= "playerctl") end
end)

test("a reload discards a result waiting for keyboard focus restoration", function(session)
    session.press(modifier .. "Y")
    local request = session.map_picker()
    rofi_picker_selected(request.token, 0)
    session.emit("layer.closed", { pid = 5000 })
    session.emit("config.unload")
    session.flush()
    for _, command in ipairs(session.commands) do assert(command.arguments[1] ~= "playerctl") end
end)

test("G cycles regular workspaces by last focus", function(session)
    session.space("special:test")
    session.press(modifier .. "H")
    session.press(modifier .. "H")
    session.press(modifier .. "G")
    session.press("Control_R")
    assert(session.current.id == 2)
end)

test("Shift G starts at the opposite end of the MRU list", function(session)
    session.press(modifier .. "SHIFT + G")
    session.press("Super_L")
    assert(session.current.id == 10)
end)

test("removed workspaces are not recreated by stale selection", function(session)
    session.press(modifier .. "G")
    session.spaces["2"] = nil
    session.choose(1)
    assert(session.current.id == 1 and not session.spaces["2"])
end)

test("Y starts with Play/Pause and is confirmed by a quick release", function(session)
    session.press(modifier .. "Y")
    session.press("Alt_R")
    local command = session.commands[#session.commands].arguments
    assert(command[1] == "playerctl" and command[3] == "spotify" and command[4] == "play-pause")
end)

test("Y has a fixed Next, Previous, Spotify order", function(session)
    for index, command in ipairs({ "next", "previous", "spotify" }) do
        session.press(modifier .. "Y")
        session.choose(index)
        local arguments = session.commands[#session.commands].arguments
        assert(command == "spotify" and arguments[1] == "spotify" or arguments[4] == command)
    end
end)

test("reverse Y starts at Spotify and reuses navigation for an existing instance", function(session)
    local spotify = session.add("spotify", 10)
    local master = session.add("kitty", 1)
    session.focus(master)
    session.press(modifier .. "SHIFT + Y")
    session.press("Control_L")
    assert(session.focused == spotify and master.workspace.id == 10)
end)

test("text launchers preserve Unicode and snippet escapes", function()
    assert(text_launcher.emoji("👩🏽‍💻 woman technologist").text == "👩🏽‍💻")
    assert(text_launcher.snippet([[Hello\n\nHenrik|greeting]]).text == "Hello\n\nHenrik")
    assert(text_launcher.snippet([[literal \\n and \t|escape]]).text == "literal \\n and \t")
    assert(not text_launcher.snippet("invalid"))
end)

test("E opens the emoji dataset and returns the selected emoji", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "E")
    session.choose(0)
    local arguments = session.commands[#session.commands].arguments
    assert(arguments[1] == "wtype" and arguments[2] == "--" and arguments[3] == "😀")
end)

test("text insertion is cancelled when the original window loses focus", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "Q")
    session.focus(session.add("kitty", 1))
    session.choose(0)
    for _, command in ipairs(session.commands) do assert(command.arguments[1] ~= "wtype") end
end)

test("literal text remains one safely quoted command argument", function()
    local command = process.command({ "wtype", "--", "a'b $(touch /tmp/never) `false`\n-next" })
    assert(command == "'wtype' '--' 'a'\\''b $(touch /tmp/never) `false`\n-next'")
    assert(not pcall(process.command, { "wtype", "a\0b" }))
end)

test("dispatch failures stop navigation before focus changes", function(session)
    local code = session.add("code", 2)
    code.fail_move = true
    assert(not pcall(session.press, modifier .. "K"))
    assert(session.focused == nil and code.workspace.id == 2)
end)

print(string.format("%d Hyprland scenarios passed", passed))
