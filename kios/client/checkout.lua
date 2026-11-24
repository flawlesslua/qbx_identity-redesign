--[[
    Customer side of the self-service checkout: receipt panel, sounds and actions.
]]

Checkout = {}

local active = nil          -- fid of the register the receipt belongs to
local lastStage = {}        -- [fid] = stage
local lastScanned = {}      -- [fid] = scanned count
local busy = false
local trackReceipt = Nui.tracker('receiptPos')

local function me()
    return cache.serverId
end

---Groups products into receipt lines: { label, qty, price }.
local function lines(products, limit)
    local shop = Shop.current
    local order, byKey = {}, {}
    local subtotal = 0
    for i, p in ipairs(products) do
        if limit and i > limit then break end
        local def = Config.Products[p]
        local price = Kios.price(shop and shop.prices, p)
        subtotal = subtotal + price
        local line = byKey[p]
        if not line then
            line = { label = def and def.label or p, qty = 0, price = 0 }
            byKey[p] = line
            order[#order + 1] = line
        end
        line.qty = line.qty + 1
        line.price = line.price + price
    end
    for _, line in ipairs(order) do line.priceText = Kios.money(line.price) end
    return order, subtotal
end

local function showReceipt(reg)
    local stage, items, total
    if reg.stage == 'paid' and reg.bag then
        stage = 'paid'
        items, total = lines(reg.bag.items)
        total = reg.bag.total
    elseif reg.stage == 'scanning' then
        stage = 'scanning'
        items, total = lines(reg.items, reg.scanned)
    elseif reg.stage == 'pay' then
        stage = 'pay'
        items = lines(reg.items)
        total = reg.total
    end
    if not stage then return Nui.send('receipt', false) end

    local count = stage == 'paid' and #reg.bag.items or #reg.items
    Nui.send('receipt', {
        stage = stage,
        items = items,
        count = count,
        scanned = reg.scanned,
        total = Kios.money(total or 0),
    })
end

function Checkout.onRegister(fid, reg)
    local mine = reg and (reg.customer == me() or (reg.bag and reg.bag.owner == me()))
    local prevStage, prevScanned = lastStage[fid], lastScanned[fid] or 0
    lastStage[fid] = reg and reg.stage or nil
    lastScanned[fid] = reg and reg.scanned or 0

    if not mine then
        if active == fid then
            active = nil
            Nui.send('receipt', false)
            trackReceipt(nil)
        end
        return
    end

    active = fid
    showReceipt(reg)

    if reg.stage == 'scanning' or reg.stage == 'pay' then
        if (reg.scanned or 0) > prevScanned then Nui.send('sound', 'scan') end
    end
    if reg.stage == 'paid' and prevStage ~= 'paid' then
        Nui.send('sound', 'paid')
    end
end

function Checkout.clear()
    active = nil
    lastStage, lastScanned = {}, {}
    Nui.send('receipt', false)
    trackReceipt(nil)
end

---Called every frame by the target loop while inside a shop.
function Checkout.frame()
    local shop = Shop.current
    if not active or not shop then return end
    local furn = shop.furniture[active]
    local def = furn and Config.Furniture[furn.type].register
    if not def then return trackReceipt(nil) end
    trackReceipt(Kios.toWorld(furn.coords, furn.heading, def.panel))
end

local function call(name, fid, ...)
    if busy or not Shop.current then return end
    busy = true
    local ok, err = lib.callback.await(name, false, Shop.current.id, fid, ...)
    if not ok and err then
        lib.notify({ description = locale(err), type = 'error' })
    end
    SetTimeout(300, function() busy = false end)
    return ok
end

function Checkout.start(fid)
    Props.playAnim(Config.anims.place)
    call('kios:checkout:start', fid)
end

function Checkout.pay(fid, method)
    call('kios:checkout:pay', fid, method)
end

function Checkout.cancel(fid)
    call('kios:checkout:cancel', fid)
end

function Checkout.takeBag(fid)
    Props.playAnim(Config.anims.take)
    if call('kios:checkout:takeBag', fid) then
        Nui.send('sound', 'bag')
    end
end

---Label + actions for the register a player is aiming at.
function Checkout.describeRegister(fid, reg)
    local keys = Config.keys
    local mineCustomer = reg.customer == me()

    if reg.stage == 'idle' and not reg.bag then
        local actions = {}
        if Carry.count() > 0 then
            actions[1] = { id = 'checkout', key = keys.primary.label, label = locale('checkout') }
        end
        return { label = locale('register'), icon = 'register', actions = actions }
    end

    if mineCustomer and reg.stage == 'scanning' then
        return {
            label = locale('register_scanning'), icon = 'register',
            actions = { { id = 'cancel', key = keys.cancel.label, label = locale('cancel'), subtle = true } },
        }
    end

    if mineCustomer and reg.stage == 'pay' then
        local actions = {}
        if Config.checkout.methods.cash then
            actions[#actions + 1] = { id = 'cash', key = keys.primary.label, label = locale('cash') }
        end
        if Config.checkout.methods.card then
            actions[#actions + 1] = { id = 'card', key = keys.secondary.label, label = locale('card') }
        end
        actions[#actions + 1] = { id = 'cancel', key = keys.cancel.label, label = locale('cancel'), subtle = true }
        return { label = locale('total', Kios.money(reg.total)), icon = 'card', actions = actions }
    end

    if reg.bag and reg.bag.owner == me() then return end
    return { label = locale('register_busy'), icon = 'register', actions = {} }
end

function Checkout.describeBag(reg)
    if not reg.bag then return end
    if reg.bag.owner == me() then
        return {
            label = locale('your_purchase'),
            actions = { { id = 'take_bag', key = Config.keys.primary.label, label = locale('take_bag') } },
        }
    end
    return { label = locale('purchase'), actions = {} }
end
