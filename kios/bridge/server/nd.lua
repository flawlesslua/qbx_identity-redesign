if Bridge.name ~= 'nd' then return end

local function player(src)
    return exports.ND_Core:getPlayer(src)
end

function Bridge.getIdentifier(src)
    local p = player(src)
    return p and tostring(p.id)
end

function Bridge.getName(src)
    local p = player(src)
    if not p then return GetPlayerName(src) end
    return p.fullname or ('%s %s'):format(p.firstname or '', p.lastname or '')
end

function Bridge.getMoney(src, account)
    local p = player(src)
    return p and p[account] or 0
end

function Bridge.removeMoney(src, account, amount, reason)
    local p = player(src)
    if not p or (p[account] or 0) < amount then return false end
    return p.deductMoney(account, amount, reason) and true or false
end

function Bridge.addMoney(src, account, amount, reason)
    local p = player(src)
    if not p then return false end
    return p.addMoney(account, amount, reason) and true or false
end
