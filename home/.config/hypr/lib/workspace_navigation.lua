local compositor = require("lib.compositor")
local workspace_navigation = {}

function workspace_navigation.show(address)
    local workspace = hl.get_workspace(address)
    if workspace and not workspace.special then
        compositor.dispatch(hl.dsp.focus({ workspace = address }))
    end
end

function workspace_navigation.new(picker)
    local navigation = {}
    local visits, visit_sequence = {}, 0
    local last_workspace

    local function remember(workspace)
        if not workspace or workspace.special or workspace.addressable_name == last_workspace then return end
        visit_sequence = visit_sequence + 1
        last_workspace = workspace.addressable_name
        visits[last_workspace] = visit_sequence
    end
    remember(hl.get_last_workspace())
    remember(hl.get_active_workspace())
    local function remember_active_workspace() remember(hl.get_active_workspace()) end
    for _, event in ipairs({ "workspace.active", "monitor.focused", "window.active" }) do
        hl.on(event, remember_active_workspace)
    end

    function navigation.list()
        local items = {}
        for _, workspace in ipairs(hl.get_workspaces()) do
            if not workspace.special then
                items[#items + 1] = {
                    address = workspace.addressable_name,
                    label = workspace.name ~= "" and workspace.name or workspace.addressable_name,
                    id = workspace.id,
                }
            end
        end
        table.sort(items, function(first, second)
            local first_visit, second_visit = visits[first.address] or 0, visits[second.address] or 0
            if first_visit ~= second_visit then return first_visit > second_visit end
            if first.id and second.id and first.id ~= second.id then return first.id < second.id end
            return first.address < second.address
        end)
        return items
    end

    function navigation.cycle(direction, key)
        if picker.is_open() then return end
        local workspace = compositor.active_workspace()
        if not workspace then return end
        remember_active_workspace()
        local items = navigation.list()
        picker.open(items, {
            cycle_key = key,
            initial_index = compositor.next_index(items, direction, workspace.addressable_name),
            on_select = function(item) workspace_navigation.show(item.address) end,
        })
    end

    function navigation.switch_between(workspaces)
        if #workspaces == 0 then return end
        local current = compositor.active_workspace()
        local target = workspaces[1]
        for index, workspace in ipairs(workspaces) do
            if current and current.addressable_name == tostring(workspace) then
                target = workspaces[index % #workspaces + 1]
                break
            end
        end
        compositor.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
    end

    return navigation
end

return workspace_navigation
