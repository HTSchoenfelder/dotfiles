local ApplicationGroups = {}
ApplicationGroups.__index = ApplicationGroups

function ApplicationGroups.new(options)
  local byID = {}
  for _, application in ipairs(options.applications) do
    if application.id then
      assert(not byID[application.id], "Duplicate application ID: " .. application.id)
      byID[application.id] = application
    end
  end
  return setmetatable({
    byID = byID,
    commaSelection = options.commaSelection,
    navigation = options.navigation,
    orchestrator = options.orchestrator,
    gate = options.gate,
  }, ApplicationGroups)
end

function ApplicationGroups:cycle(group, direction, chooseInstance, mode)
  local kind = "application_group:" .. group.key
  local session = self.commaSelection.session
  local continuing = session and session.kind == kind
  local generation = continuing and session.generation or self.gate:next()
  local request = continuing and session.request
    or self.orchestrator:capture(mode, generation)
  if not request then return end

  local items = {}
  for _, id in ipairs(group.applications) do
    local application = assert(self.byID[id], "Unknown grouped application: " .. id)
    items[#items + 1] = {
      id = application.bundleID,
      text = application.name,
      image = hs.image.imageFromAppBundle(application.bundleID),
      application = application,
    }
  end
  if #items == 0 then return end

  self.commaSelection:cycle(kind, direction, {
    currentID = direction > 0 and items[#items].id or items[1].id,
    screen = request.screen,
    load = function(done) done(items) end,
    onSelect = function(item)
      hs.timer.doAfter(0, function()
        self.navigation:activate(item.application, request.mode, chooseInstance, request)
      end)
    end,
  })
  if self.commaSelection.session then
    self.commaSelection.session.generation = generation
    self.commaSelection.session.request = request
  end
end

return ApplicationGroups
