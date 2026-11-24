--[[
    Framework bridge. Kios keeps shop ownership, staff and balances in its own tables, so the
    bridge only needs: who the player is, their character name, and their money.

    Detection order matters: qbx_core provides 'qb-core' too, so it is checked first.
    Force a framework with:  setr kios:framework "qbx"   (qbx | qb | esx | ox | nd)
]]

Bridge = { name = nil }

local candidates = {
    { name = 'qbx', resource = 'qbx_core' },
    { name = 'esx', resource = 'es_extended' },
    { name = 'qb', resource = 'qb-core' },
    { name = 'ox', resource = 'ox_core' },
    { name = 'nd', resource = 'ND_Core' },
}

local forced = GetConvar('kios:framework', '')
if forced ~= '' then
    Bridge.name = forced
else
    for _, c in ipairs(candidates) do
        local state = GetResourceState(c.resource)
        if state == 'started' or state == 'starting' then
            Bridge.name = c.name
            break
        end
    end
end

if not Bridge.name then
    Bridge.name = 'standalone'
end

print(('[kios] framework bridge: %s'):format(Bridge.name))

-- Defaults (standalone). Framework files below override what they support.

function Bridge.getIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license') or tostring(src)
end

function Bridge.getName(src)
    return GetPlayerName(src) or ('Player %s'):format(src)
end

local function invMoney(src)
    return exports.ox_inventory:GetItemCount(src, 'money') or 0
end

function Bridge.getMoney(src, account)
    if account == 'cash' then return invMoney(src) end
    return 0
end

function Bridge.removeMoney(src, account, amount, reason)
    if amount <= 0 then return true end
    if account == 'cash' then
        if invMoney(src) < amount then return false end
        return exports.ox_inventory:RemoveItem(src, 'money', amount) and true or false
    end
    return false
end

function Bridge.addMoney(src, account, amount, reason)
    if amount <= 0 then return true end
    if account == 'cash' then
        return exports.ox_inventory:AddItem(src, 'money', amount) and true or false
    end
    return false
end
