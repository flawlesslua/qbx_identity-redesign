if Bridge.name ~= 'esx' then return end

local ESX = exports.es_extended:getSharedObject()

-- ESX calls cash "money".
local accounts = { cash = 'money', bank = 'bank' }

local function player(src)
    return ESX.GetPlayerFromId(src)
end

function Bridge.getIdentifier(src)
    local p = player(src)
    return p and p.identifier
end

function Bridge.getName(src)
    local p = player(src)
    return p and p.getName() or GetPlayerName(src)
end

function Bridge.getMoney(src, account)
    local p = player(src)
    local acc = p and p.getAccount(accounts[account] or account)
    return acc and acc.money or 0
end

function Bridge.removeMoney(src, account, amount, reason)
    local p = player(src)
    if not p or Bridge.getMoney(src, account) < amount then return false end
    p.removeAccountMoney(accounts[account] or account, amount, reason)
    return true
end

function Bridge.addMoney(src, account, amount, reason)
    local p = player(src)
    if not p then return false end
    p.addAccountMoney(accounts[account] or account, amount, reason)
    return true
end
