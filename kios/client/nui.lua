Nui = { ready = false }

local uiKeys = {
    'ui_to_pay', 'ui_scanning', 'ui_scanning_desc', 'ui_paid', 'ui_total', 'ui_item', 'ui_items',
}

function Nui.send(action, data)
    SendNUIMessage({ action = action, data = data })
end

RegisterNUICallback('ready', function(_, cb)
    Nui.ready = true
    local strings = { currency = Config.currency }
    for _, key in ipairs(uiKeys) do strings[key] = locale(key) end
    Nui.send('locale', strings)
    cb(1)
end)

---Screen position (0..1) of a world position, or nil when it is off screen.
function Nui.screen(pos)
    local onScreen, x, y = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
    if not onScreen then return end
    return x, y
end

---Keeps a NUI element glued to a world position. Only sends when it actually moved.
---@param action string NUI action receiving { x, y } or false
function Nui.tracker(action)
    local lastX, lastY, hidden = -1, -1, true
    return function(pos)
        local x, y
        if pos then x, y = Nui.screen(pos) end
        if not x then
            if not hidden then
                hidden = true
                lastX, lastY = -1, -1
                Nui.send(action, false)
            end
            return
        end
        if hidden or math.abs(x - lastX) > 0.0006 or math.abs(y - lastY) > 0.0006 then
            hidden = false
            lastX, lastY = x, y
            Nui.send(action, { x = x, y = y })
        end
    end
end
