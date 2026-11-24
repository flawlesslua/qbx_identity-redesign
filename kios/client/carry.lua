--[[
    Products in hands. The server writes the list to the player's state bag ('kiosCarry');
    every client attaches local props to that player's ped, so it works with entity lockdown.
]]

Carry = {}

local attached = {}   -- [serverId] = { key = string, ped = integer, objs = integer[] }
local busy = false

function Carry.mine()
    return LocalPlayer.state.kiosCarry or {}
end

function Carry.count()
    return #Carry.mine()
end

function Carry.holding(product)
    for _, p in ipairs(Carry.mine()) do
        if p == product then return true end
    end
    return false
end

local function clear(serverId)
    local entry = attached[serverId]
    if not entry then return end
    Props.deleteAll(entry.objs)
    attached[serverId] = nil
end

local function intact(entry, ped)
    if entry.ped ~= ped then return false end
    for _, obj in ipairs(entry.objs) do
        if not DoesEntityExist(obj) then return false end
    end
    return true
end

local function render(serverId, list)
    local player = GetPlayerFromServerId(serverId)
    local ped = player ~= -1 and GetPlayerPed(player) or 0
    local key = table.concat(list or {}, ',')
    local entry = attached[serverId]

    if ped == 0 or key == '' then return clear(serverId) end
    if entry and entry.key == key and intact(entry, ped) then return end
    clear(serverId)

    entry = { key = key, ped = ped, objs = {} }
    attached[serverId] = entry
    for i = 1, math.min(#list, #Config.carryBones) do
        local def = Config.Products[list[i]]
        if def then
            local obj = Props.spawn(def.model, GetEntityCoords(ped), 0.0, { dynamic = true })
            if attached[serverId] ~= entry then return Props.delete(obj) end
            if obj then
                local hold = def.hold
                AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, Config.carryBones[i]),
                    hold.pos.x, hold.pos.y, hold.pos.z, hold.rot.x, hold.rot.y, hold.rot.z,
                    true, true, false, true, 1, true)
                entry.objs[#entry.objs + 1] = obj
            end
        end
    end
end

AddStateBagChangeHandler('kiosCarry', nil, function(bagName, _, value)
    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 then return end
    local serverId = GetPlayerServerId(player)
    CreateThread(function() render(serverId, value) end)
end)

-- Reconcile: players streaming in/out, peds respawning.
CreateThread(function()
    while true do
        Wait(1000)
        local seen = {}
        local myCoords = GetEntityCoords(cache.ped)
        for _, player in ipairs(GetActivePlayers()) do
            local serverId = GetPlayerServerId(player)
            local ped = GetPlayerPed(player)
            if #(GetEntityCoords(ped) - myCoords) < 60.0 then
                local list = Player(serverId).state.kiosCarry
                if list and #list > 0 then
                    seen[serverId] = true
                    render(serverId, list)
                end
            end
        end
        for serverId in pairs(attached) do
            if not seen[serverId] then clear(serverId) end
        end
    end
end)

local function act(callback, anim, ...)
    if busy or not Shop.current then return end
    busy = true
    Props.playAnim(anim)
    local ok, err = lib.callback.await(callback, false, Shop.current.id, ...)
    if not ok and err then
        lib.notify({ description = locale(err), type = 'error' })
    end
    SetTimeout(250, function() busy = false end)
end

function Carry.take(furn, index)
    if Carry.count() >= Config.maxCarry then
        return lib.notify({ description = locale('hands_full'), type = 'error' })
    end
    act('kios:take', Config.anims.take, furn.id, index)
end

function Carry.drop(furn, index)
    act('kios:drop', Config.anims.place, furn.id, index)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for serverId in pairs(attached) do clear(serverId) end
end)
