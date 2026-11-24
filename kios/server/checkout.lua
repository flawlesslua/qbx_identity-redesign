--[[
    Self-service checkout:
        idle --(customer puts products on the counter)--> scanning --> pay --(cash/card)--> paid
        paid --(customer takes the bag)--> idle
]]

Checkout = {}

local function registerDef(shop, reg)
    local furn = shop.furniture[reg.fid]
    return furn, furn and Config.Furniture[furn.type].register
end

local function anchorPos(furn, offset)
    return Kios.toWorld(furn.coords, furn.heading, offset or vec3(0.0, 0.0, 0.0))
end

function Checkout.emit(shop, reg)
    State.emit(shop, 'kios:c:register', reg.fid, State.serializeRegister(reg))
end

local function getRegister(src, shopId, fid)
    local shop = State.subscribedShop(src, shopId)
    local reg = shop and shop.registers[fid]
    if not reg then return end
    local furn, def = registerDef(shop, reg)
    if not furn then return end
    return shop, reg, furn, def
end

local function scheduleScan(shop, reg)
    local session = reg.session
    local count = #reg.items
    for i = 1, count do
        SetTimeout(i * Config.checkout.scanTime, function()
            if reg.session ~= session or reg.stage ~= 'scanning' then return end
            reg.scanned = i
            if i >= count then reg.stage = 'pay' end
            Checkout.emit(shop, reg)
        end)
    end
end

lib.callback.register('kios:checkout:start', function(src, shopId, fid)
    local shop, reg, furn, def = getRegister(src, shopId, fid)
    if not shop then return false end
    if reg.mode ~= 'self' then return false end
    if reg.stage ~= 'idle' or reg.bag then return false, 'register_busy' end
    if not State.near(src, anchorPos(furn, def.anchor), Config.target.distance + 1.5) then return false end

    local items = Carry.takeAll(src)
    if #items == 0 then return false, 'nothing_in_hands' end

    local total = 0
    for _, item in ipairs(items) do total = total + Kios.price(shop.prices, item.p) end

    reg.items = items
    reg.customer = src
    reg.stage = 'scanning'
    reg.scanned = 0
    reg.total = total
    reg.session = reg.session + 1
    Checkout.emit(shop, reg)
    scheduleScan(shop, reg)
    return true
end)

function Checkout.cancel(shop, reg, toHand)
    if reg.stage ~= 'scanning' and reg.stage ~= 'pay' then return end
    local customer, items = reg.customer, reg.items
    reg.items, reg.customer, reg.stage, reg.scanned, reg.total = {}, nil, 'idle', 0, 0
    reg.session = reg.session + 1
    if toHand and customer and GetPlayerPed(customer) ~= 0 then
        Carry.giveBack(customer, shop, items)
        State.notify(customer, 'checkout_cancelled', 'inform')
    else
        Carry.returnToShelves(shop, items)
    end
    Checkout.emit(shop, reg)
end

lib.callback.register('kios:checkout:cancel', function(src, shopId, fid)
    local shop, reg = getRegister(src, shopId, fid)
    if not shop or reg.customer ~= src then return false end
    Checkout.cancel(shop, reg, true)
    return true
end)

local function deliver(src, items)
    local counts = {}
    for _, item in ipairs(items) do
        local def = Config.Products[item.p]
        if def then counts[def.item] = (counts[def.item] or 0) + 1 end
    end
    for name, count in pairs(counts) do
        if not exports.ox_inventory:CanCarryItem(src, name, count) then return false end
    end
    for name, count in pairs(counts) do
        exports.ox_inventory:AddItem(src, name, count)
    end
    return true
end

local function clearBag(shop, reg)
    reg.bag = nil
    reg.stage = 'idle'
    reg.customer = nil
    reg.session = reg.session + 1
    Checkout.emit(shop, reg)
end

local function scheduleBagTimeout(shop, reg)
    local bag = reg.bag
    SetTimeout(Config.checkout.bagTimeout * 1000, function()
        if reg.bag ~= bag then return end
        local owner = bag.owner
        if GetPlayerPed(owner) ~= 0 and deliver(owner, bag.items) then
            State.notify(owner, 'bag_delivered', 'success')
            clearBag(shop, reg)
        elseif GetPlayerPed(owner) == 0 then
            DB.log(shop.id, 'bag_lost', bag.total, nil, nil, { register = reg.fid })
            clearBag(shop, reg)
        else
            scheduleBagTimeout(shop, reg)
        end
    end)
end

lib.callback.register('kios:checkout:pay', function(src, shopId, fid, method)
    local shop, reg, furn, def = getRegister(src, shopId, fid)
    if not shop or reg.customer ~= src or reg.stage ~= 'pay' then return false end
    if method ~= 'cash' and method ~= 'card' then return false end
    if not Config.checkout.methods[method] then return false end
    if not State.near(src, anchorPos(furn, def.anchor), Config.target.distance + 1.5) then return false end

    local account = method == 'cash' and 'cash' or 'bank'
    if not Bridge.removeMoney(src, account, reg.total, ('kios purchase (%s)'):format(shop.id)) then
        return false, 'not_enough_money'
    end

    local products = {}
    for i, item in ipairs(reg.items) do products[i] = item.p end

    State.addBalance(shop, reg.total)
    DB.log(shop.id, 'sale', reg.total, Bridge.getIdentifier(src), Bridge.getName(src), {
        items = products, method = method, register = fid,
    })

    reg.bag = { owner = src, items = reg.items, total = reg.total }
    reg.items = {}
    reg.stage = 'paid'
    reg.session = reg.session + 1
    Checkout.emit(shop, reg)
    scheduleBagTimeout(shop, reg)
    return true, reg.bag.total
end)

lib.callback.register('kios:checkout:takeBag', function(src, shopId, fid)
    local shop, reg, furn, def = getRegister(src, shopId, fid)
    if not shop or not reg.bag or reg.bag.owner ~= src then return false end
    if not State.near(src, anchorPos(furn, def.bag), Config.target.distance + 1.5) then return false end
    if not deliver(src, reg.bag.items) then return false, 'cant_carry' end
    clearBag(shop, reg)
    return true
end)

---Runs every second from server/main.lua.
function Checkout.tick()
    for _, shop in pairs(State.shops) do
        for _, reg in pairs(shop.registers) do
            local customer = reg.customer
            if customer and (reg.stage == 'scanning' or reg.stage == 'pay') then
                local furn, def = registerDef(shop, reg)
                if GetPlayerPed(customer) == 0 then
                    Checkout.cancel(shop, reg, false)
                elseif furn and not State.near(customer, anchorPos(furn, def.anchor), Config.checkout.walkAwayDistance) then
                    Checkout.cancel(shop, reg, true)
                end
            end
        end
    end
end

function Checkout.dropped(src)
    for _, shop in pairs(State.shops) do
        for _, reg in pairs(shop.registers) do
            if reg.customer == src and (reg.stage == 'scanning' or reg.stage == 'pay') then
                Checkout.cancel(shop, reg, false)
            elseif reg.bag and reg.bag.owner == src then
                DB.log(shop.id, 'bag_lost', reg.bag.total, nil, nil, { register = reg.fid })
                clearBag(shop, reg)
            end
        end
    end
end

---Used when a register is removed by an admin.
function Checkout.release(shop, reg)
    Checkout.cancel(shop, reg, true)
    if reg.bag then
        local owner = reg.bag.owner
        if GetPlayerPed(owner) ~= 0 then deliver(owner, reg.bag.items) end
        reg.bag = nil
    end
end
