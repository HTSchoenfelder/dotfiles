local catalog = require("shortcut_catalog")

local Launcher = {}
Launcher.__index = Launcher

local spotlightQuery = "kMDItemContentType == 'com.apple.application-bundle'c"
local home = os.getenv("HOME")
local applicationRoots = {
  "/Applications",
  "/Applications/Nix Apps",
  "/Applications/Xcode.app/Contents/Applications",
  "/Developer/Applications",
  "/System/Applications",
  "/System/Applications/Utilities",
  "/System/Library/CoreServices/Applications",
  home .. "/Applications",
  home .. "/Applications/Chrome Apps.localized",
}

local function isTopLevelApplication(path)
  for _, root in ipairs(applicationRoots) do
    local prefix = root .. "/"
    if path:sub(1, #prefix) == prefix
        and path:sub(#prefix + 1):match("^[^/]+%.app$") then
      return true
    end
  end
  return false
end

function Launcher.new(options)
  return setmetatable({
    chooserFactory = options.chooserFactory,
    modifiers = options.modifiers,
    gate = options.gate,
    task = nil,
    chooser = nil,
    generation = 0,
  }, Launcher)
end

function Launcher:_choices(output)
  local applications = {}
  local seen = {}
  for path in output:gmatch("[^\r\n]+") do
    if isTopLevelApplication(path) then
      local info = hs.application.infoForBundlePath(path)
      local bundleID = info and (info.CFBundleIdentifier or info.bundleID)
      local name = info and (info.CFBundleDisplayName or info.CFBundleName)
        or path:match("([^/]+)%.app$")
      local identity = bundleID or path
      if name and not seen[identity] then
        seen[identity] = true
        applications[#applications + 1] = {
          text = name,
          path = path,
          bundleID = bundleID,
          image = bundleID and hs.image.imageFromAppBundle(bundleID)
            or hs.image.iconForFile(path),
        }
      end
    end
  end
  table.sort(applications, function(first, second)
    return first.text:lower() < second.text:lower()
  end)
  return applications
end

function Launcher:toggle()
  if self.gate then self.gate:next() end
  if self.chooser and self.chooser:isVisible() then
    self.chooser:hide()
    return
  end
  self.generation = self.generation + 1
  local generation = self.generation
  if self.task and self.task:isRunning() then self.task:terminate() end
  self.task = hs.task.new("/usr/bin/mdfind", function(exitCode, stdout, stderr)
    self.task = nil
    if generation ~= self.generation then return end
    if exitCode ~= 0 then
      hs.notify.new({title = "Application launcher", informativeText = stderr}):send()
      return
    end
    local choices = self:_choices(stdout)
    self.chooser = self.chooserFactory()
    self.chooser:show(choices, function(selected)
      if selected then hs.application.launchOrFocus(selected.path) end
    end)
  end, {spotlightQuery})
  self.task:start()
end

function Launcher:start()
  self.binding = hs.hotkey.bind(self.modifiers, "r", function() self:toggle() end)
  catalog.add("Launchers", "MainMod + R", "Toggle application launcher")
end

return Launcher
