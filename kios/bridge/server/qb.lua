if Bridge.name ~= 'qb' then return end

local QBCore = exports['qb-core']:GetCoreObject()

local function player(src)
    return QBCore.Functions.GetPlayer(src)
end

function Bridge.getIdentifier(src)
    local p = player(src)
    return p and p.PlayerData.citizenid
end

function Bridge.getName(src)
    local p = player(src)
    if not p then return GetPlayerName(src) end
    local info = p.PlayerData.charinfo
    return ('%s %s'):format(info.firstname, info.lastname)
end

function Bridge.getMoney(src, account)
    local p = player(src)
    return p and p.PlayerData.money[account] or 0
end

function Bridge.removeMoney(src, account, amount, reason)
    local p = player(src)
    if not p or (p.PlayerData.money[account] or 0) < amount then return false end
    return p.Functions.RemoveMoney(account, amount, reason) and true or false
end

function Bridge.addMoney(src, account, amount, reason)
    local p = player(src)
    if not p then return false end
    return p.Functions.AddMoney(account, amount, reason) and true or false
end
