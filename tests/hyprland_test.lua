-- Run from the repository root: lua tests/hyprland_test.lua
package.path = "home/.config/hypr/?.lua;tests/?.lua;" .. package.path
local support = require("hyprland_support")
local windows = require("lib.window_navigation")
local text_launcher = require("lib.text_launcher")
local process = require("lib.process")
local modifier = "SUPER + CTRL + ALT + "
local passed = 0

local function picker_index(session, label)
    local request = assert(session.picker_request())
    local rows = assert(io.open(request.path))
    local index = 0
    for row in rows:lines() do
        if row == label then rows:close(); return index end
        index = index + 1
    end
    rows:close()
    error("Missing picker row: " .. label)
end

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
    session.flush(50)
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

test("A limits comma selection to instances of the focused application", function(session)
    local current = session.add("unconfigured-app", 1, 0)
    local previous = session.add("Unconfigured-App", 2, 1)
    session.add("kitty", 1, 2)
    session.focus(current)
    session.held.a = true
    session.press(modifier .. "comma")
    local request = assert(session.picker_request())
    local rows = assert(io.open(request.path))
    assert(rows:read("*a") == "unconfigured-app\nUnconfigured-App\n")
    rows:close()
    session.press("Alt_L")
    assert(session.focused == previous)
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
    session.press(modifier .. "period")
    session.press("E")
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

test("period E opens the emoji dataset and returns the selected emoji", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "period")
    session.press("E")
    session.choose(0)
    local arguments = session.commands[#session.commands].arguments
    assert(arguments[1] == "wtype" and arguments[2] == "--" and arguments[3] == "😀")
end)

test("text insertion is cancelled when the original window loses focus", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "period")
    session.press("T")
    session.focus(session.add("kitty", 1))
    session.choose(0)
    for _, command in ipairs(session.commands) do assert(command.arguments[1] ~= "wtype") end
end)

test("literal text remains one safely quoted command argument", function()
    local command = process.command({ "wtype", "--", "a'b $(touch /tmp/never) `false`\n-next" })
    assert(command == "'wtype' '--' 'a'\\''b $(touch /tmp/never) `false`\n-next'")
    assert(not pcall(process.command, { "wtype", "a\0b" }))
end)

test("dot mode stays visible until Q captures a region", function(session)
    assert(session.bindings[modifier .. "period"].options.dont_inhibit)
    assert(session.bindings["dot:Q"].options.dont_inhibit)
    session.press(modifier .. "period")
    assert(session.submap == "dot" and #session.commands == 0)
    local notice = session.notices[#session.notices]
    assert(notice.options.text == "dot mode" and notice.paused and notice.alive)
    session.press("Q")
    assert(session.submap == "reset" and not notice.alive)
    assert(table.concat(session.commands[1].arguments, " ") == "hyprshot --mode region")
end)

test("dot mode captures the active window with A and active output with Z", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "period")
    session.press("A")
    assert(session.submap == "reset")
    assert(table.concat(session.commands[1].arguments, " ") == "hyprshot --mode window --mode active")
    session.press(modifier .. "period")
    session.press("Z")
    assert(table.concat(session.commands[2].arguments, " ") == "hyprshot --mode output --mode active")
end)

test("Escape and unknown keys leave dot mode without capturing", function(session)
    for _, key in ipairs({ "Escape", "X" }) do
        session.press(modifier .. "period")
        session.press(key)
        assert(session.submap == "reset" and #session.commands == 0)
    end
end)

test("entering dot mode cancels pending Rofi selections", function(session)
    session.press(modifier .. "Y")
    local request = session.map_picker()
    session.press(modifier .. "period")
    rofi_picker_selected(request.token, 0)
    session.emit("layer.closed", { pid = 5000 })
    session.flush()
    for _, command in ipairs(session.commands) do assert(command.arguments[1] ~= "playerctl") end
    assert(session.submap == "dot")
end)

test("dispatch failures stop navigation before focus changes", function(session)
    local code = session.add("code", 2)
    code.fail_move = true
    assert(not pcall(session.press, modifier .. "K"))
    assert(session.focused == nil and code.workspace.id == 2)
end)

test("Ctrl shortcuts map browser actions to the focused Chrome window", function(session)
    local chrome = session.add("google-chrome", 1)
    session.focus(chrome)
    local expected = { p = { "CTRL SHIFT", "a" }, h = { "ALT", "Left" },
        j = { "CTRL SHIFT", "Tab" }, k = { "CTRL", "Tab" }, l = { "ALT", "Right" } }
    for key, shortcut in pairs(expected) do
        session.press("CTRL + " .. key)
        local actual = session.shortcuts[#session.shortcuts]
        assert(actual.mods == shortcut[1] and actual.key == shortcut[2] and actual.window == chrome)
    end
    assert(#session.commands == 0)
end)

test("Ctrl shortcuts follow focus and pass unchanged to other applications", function(session)
    session.focus(session.add("google-chrome", 1))
    session.press("CTRL + p")
    local editor = session.add("code", 1)
    session.focus(editor)
    for _, key in ipairs({ "p", "h", "j", "k", "l" }) do
        session.press("CTRL + " .. key)
        local actual = session.shortcuts[#session.shortcuts]
        assert(actual.mods == "CTRL" and actual.key == key and actual.window == editor)
    end
    editor.mapped = false
    session.press("CTRL + p")
    session.focus(nil)
    session.press("CTRL + p")
    assert(#session.shortcuts == 6)
end)

test("period R opens configured commands without a focused window and waits for selection", function(session)
    session.press(modifier .. "period")
    session.press("R")
    assert(session.submap == "reset" and #session.commands == 1)
    local request = session.map_picker()
    rofi_picker_selected(request.token, picker_index(session, "notify hallo"))
    assert(#session.commands == 1)
    session.emit("layer.closed", { namespace = "rofi", pid = 5000 })
    session.flush()
    local arguments = session.commands[#session.commands].arguments
    assert(arguments[1] == "bash" and arguments[2] == "-c" and arguments[3] == 'notify-send "Hallo"')
end)

test("workspace reset restores displays and focuses the terminal workspace", function(session)
    require("lib.monitor_configuration").set_workspace_roles({
        primary = "HDMI-A-1", secondary = "HDMI-A-2",
    })
    session.monitors[2].enabled = true
    local code = session.add("code", 1, 0)
    local terminal = session.add("kitty", 10, 1)
    session.focus(code)
    session.press(modifier .. "period")
    session.press("R")
    session.choose(picker_index(session, "reset workspaces"))

    assert(session.spaces["1"].monitor.name == "HDMI-A-1")
    assert(session.spaces["2"].monitor.name == "HDMI-A-2")
    assert(session.spaces["10"].monitor.name == "HDMI-A-1")
    assert(session.current == session.spaces["1"] and session.focused == terminal)
    assert(terminal.workspace == session.spaces["1"] and code.workspace == session.spaces["10"])
end)

test("command cancellation never starts a configured command", function(session)
    session.press(modifier .. "period")
    session.press("R")
    session.map_picker()
    session.emit("layer.closed", { namespace = "rofi", pid = 5000 })
    session.flush()
    assert(#session.commands == 1)
end)

test("command data preserves shell syntax and duplicate labels retain row identity", function(session)
    local commands = require("lib.command_launcher")
    local picker = require("lib.rofi_picker").new({ modifier = "SHIFT", rows = 5, provider = "provider.lua" })
    local path = os.tmpname()
    local file = assert(io.open(path, "w"))
    file:write("\r\ninvalid\n |empty command\ntrue|   \n",
        "printf '%s' 'first'|duplicate\r\n",
        "printf '%s' '$HOME' | cat|duplicate\r\n")
    file:close()
    commands.open(picker, path)
    os.remove(path)
    local rows = assert(io.open(session.picker_request().path))
    assert(rows:read("*a") == "duplicate\nduplicate\n")
    rows:close()
    session.choose(1)
    assert(session.commands[#session.commands].arguments[3] == "printf '%s' '$HOME' | cat")
end)

test("period T inserts snippets and direct R remains the application launcher", function(session)
    session.focus(session.add("code", 1))
    session.press(modifier .. "period")
    session.press("T")
    assert(session.submap == "reset")
    session.choose(0)
    assert(session.commands[#session.commands].arguments[1] == "wtype")
    session.press(modifier .. "R")
    assert(table.concat(session.commands[#session.commands].arguments, " ") == "rofi -show drun")
    assert(not session.bindings[modifier .. "E"] and not session.bindings[modifier .. "Q"])
end)

test("dot B shows display status and enables the selected output", function(session)
    session.press(modifier .. "period")
    session.press("B")
    local request = assert(session.picker_request())
    local rows = assert(io.open(request.path))
    local labels = rows:read("*a")
    rows:close()
    assert(labels:find("🟢 HDMI%-A%-1 · enabled") and labels:find("⚫ HDMI%-A%-2 · disabled"))
    session.choose(1)
    assert(session.monitors[2].enabled)
    assert(session.monitor_rules[#session.monitor_rules].output == "HDMI-A-2")
end)

test("dot B refuses to disable the last active display", function(session)
    session.press(modifier .. "period")
    session.press("B")
    session.choose(0)
    assert(session.monitors[1].enabled and #session.monitor_rules == 0)
    assert(session.notices[#session.notices].options.text == "The last enabled display must remain on.")
end)

test("project overlays reuse one floating Kitty window per project and tool", function(session)
    local code = session.add("code", 1)
    code.title = "/home/henrik/dotfiles | Code"
    session.focus(code)
    session.press(modifier .. "period")
    session.press("J")
    local launch = session.commands[#session.commands]
    local class
    for index, argument in ipairs(launch.arguments) do
        if argument == "--class" then class = launch.arguments[index + 1] end
    end
    assert(class and launch.arguments[#launch.arguments] == "zsh")
    assert(launch.rules.no_initial_focus)
    local terminal = session.add(class, 1)
    session.emit("window.open", terminal)
    session.flush(50)
    session.flush(30)
    session.flush(30)
    session.flush(30)
    assert(session.focused == terminal and terminal.floating)
    assert(terminal.centered and terminal.size[1] == 1824 and terminal.size[2] == 972 and session.group_denied)
    session.press(modifier .. "period")
    session.press("J")
    assert(terminal.workspace.addressable_name == "special:project-overlays")
    assert(#session.commands == 1)
end)

test("project overlays remain floating across repeated hide and restore cycles", function(session)
    local code = session.add("code", 1)
    code.title = "/home/henrik/dotfiles | Code"
    session.focus(code)
    session.press(modifier .. "period")
    session.press("J")
    local launch = session.commands[#session.commands]
    local class
    for index, argument in ipairs(launch.arguments) do
        if argument == "--class" then class = launch.arguments[index + 1] end
    end
    local terminal = session.add(assert(class), 1)
    terminal.retile_on_move = true
    session.emit("window.open", terminal)
    session.flush(50)
    for _ = 1, 3 do session.flush(30) end

    for _ = 1, 3 do
        assert(terminal.workspace.addressable_name == "1" and terminal.floating and terminal.centered)
        session.press(modifier .. "period")
        session.press("J")
        assert(terminal.workspace.addressable_name == "special:project-overlays")
        terminal.centered = false
        session.focus(code)
        session.press(modifier .. "period")
        session.press("J")
        session.flush(30)
        session.flush(30)
        session.retile_on_next_center(terminal)
        session.flush(30)
        session.flush(30)
        session.flush(30)
        session.flush(30)
    end
    assert(terminal.workspace.addressable_name == "1" and terminal.floating and terminal.centered)
    assert(#session.commands == 1)
end)

test("dot G opens LazyVim and Shift G opens Lazygit for the active project", function(session)
    local code = session.add("code", 1)
    code.title = "/home/henrik/dotfiles | Code"
    session.focus(code)
    for _, expected in ipairs({ { "G", "nvim" }, { "SHIFT + G", "lazygit" } }) do
        session.press(modifier .. "period")
        session.press(expected[1])
        assert(session.commands[#session.commands].arguments[#session.commands[#session.commands].arguments] == expected[2])
    end
end)

print(string.format("%d Hyprland scenarios passed", passed))
