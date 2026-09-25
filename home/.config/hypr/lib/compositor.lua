local compositor = {}

function compositor.dispatch(action)
    local result = hl.dispatch(action)
    assert(result.ok, result.error or "Hyprland action failed")
end

function compositor.active_workspace()
    return hl.get_active_special_workspace() or hl.get_active_workspace()
end

function compositor.workspace_is_active(address)
    local workspace = compositor.active_workspace()
    return workspace ~= nil and workspace.addressable_name == address
end

function compositor.notify(message)
    hl.notification.create({ text = message, timeout = 5000, icon = "warning" })
end

function compositor.next_index(items, direction, current_address)
    if #items == 0 then return nil end
    local current_index = direction > 0 and 0 or 1
    for index, item in ipairs(items) do
        if item.address == current_address then
            current_index = index
            break
        end
    end
    return (current_index - 1 + direction) % #items + 1
end

return compositor
