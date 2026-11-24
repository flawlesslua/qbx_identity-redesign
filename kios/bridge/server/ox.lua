if Bridge.name ~= 'ox' then return end

--[[
    ox_core (experimental). Cash is the ox_inventory "money" item (default bridge functions).
    Bank uses the character's default account through ox_core's exports. Check this against
    the ox_core version you run; the account API has changed between releases.
]]

local function player(src)
    return exports.ox_core:GetPlayer(src)
end

local function account(src)
    local p = player(src)
    if not p or not p.charId then return end
    return exports.ox_core:GetCharacterAccount(p.charId)
end

local cashGet, cashRemove, cashAdd = Bridge.getMoney, Bridge.removeMoney, Bridge.addMoney

function Bridge.getIdentifier(src)
    local p = player(src)
    return p and p.charId and tostring(p.charId)
end

function Bridge.getName(src)
    local p = player(src)
    if p and p.get then
        return ('%s %s'):format(p.get('firstName') or '', p.get('lastName') or '')
    end
    return GetPlayerName(src)
end

function Bridge.getMoney(src, acc)
    if acc == 'cash' then return cashGet(src, acc) end
    local a = account(src)
    return a and a.balance or 0
end

function Bridge.removeMoney(src, acc, amount, reason)
    if acc == 'cash' then return cashRemove(src, acc, amount, reason) end
    local a = account(src)
    if not a or (a.balance or 0) < amount then return false end
    local result = exports.ox_core:CallAccount(a.accountId, 'removeBalance', { amount = amount, message = reason })
    return type(result) == 'table' and result.success or result == true
end

function Bridge.addMoney(src, acc, amount, reason)
    if acc == 'cash' then return cashAdd(src, acc, amount, reason) end
    local a = account(src)
    if not a then return false end
    local result = exports.ox_core:CallAccount(a.accountId, 'addBalance', { amount = amount, message = reason })
    return type(result) == 'table' and result.success or result == true
end
