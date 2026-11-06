--- @since 26.9.1

local current_directory = ya.sync(function()
	return cx.active.current.cwd
end)

local function notify_error(message)
	ya.notify({
		title = "Save File",
		content = message,
		level = "error",
		timeout = 5,
	})
end

local function entry()
	local output = os.getenv("YAZI_SAVE_OUTPUT")
	if not output or output == "" then
		return ya.emit("open", {})
	end

	local name, event = ya.input({
		pos = { "top-center", y = 3, w = 60 },
		title = "Save as:",
		value = os.getenv("YAZI_SAVE_NAME") or "",
	})
	if event ~= 1 or not name or name == "" then
		return
	end
	if name == "." or name == ".." or name:find("[/\\]") then
		return notify_error("Enter a file name without a directory.")
	end

	local target = current_directory():join(name)
	if fs.cha(target) then
		local overwrite = ya.confirm({
			pos = { "center", w = 60, h = 10 },
			title = "Replace File?",
			body = "A file named '" .. name .. "' already exists.",
		})
		if not overwrite then
			return
		end
	end

	local ok, err = fs.write(Url(output), tostring(target) .. "\n")
	if not ok then
		return notify_error(tostring(err))
	end

	ya.emit("quit", {})
end

return { entry = entry }
