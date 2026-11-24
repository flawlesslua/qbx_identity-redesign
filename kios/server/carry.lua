--[[
    Products held in a player's hands. They are not in the inventory yet: they only become
    inventory items after payment (or when someone walks out with them, see Config.theft).
]]

Carry = {
    carts = {},   -- [src] = { shop = shopId, items = { { p = product, f = furnitureId, s = spotIndex } } }
}

local lastAction = {}

local function throttled(src)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < 250 then return true end
    lastAction[src] = now
    return false
end

function Carry.get(src)
    return Carry.carts[src]
end

function Carry.sync(src)
    local cart = Carry.carts[src]
    local list = {}
    if cart then
        for i, item in ipairs(cart.items) do list[i] = item.p end
    end
    Player(src).state:set('kiosCarry', list, true)
end

---Takes every item out of the player's hands and returns the list.
function Carry.takeAll(src)
    local cart = Carry.carts[src]
    if not cart then return {} end
    local items = cart.items
    Carry.carts[src] = nil
    Carry.sync(src)
    return items
end

---Adds items to the player's hands; whatever does not fit goes back on the shelves.
function Carry.giveBack(src, shop, items)
    local cart = Carry.carts[src] or { shop = shop.id, items = {} }
    for _, item in ipairs(items) do
        if cart.shop == shop.id and #cart.items < Config.maxCarry then
            cart.items[#cart.items + 1] = item
        else
            State.restockOne(shop, item.p, item.f, item.s)
        end
    end
    Carry.carts[src] = #cart.items > 0 and cart or nil
    Carry.sync(src)
end

function Carry.returnToShelves(shop, items)
    for _, item in ipairs(items) do
        if not State.restockOne(shop, item.p, item.f, item.s) then
            print(('[kios] no room to return %s in %s, unit lost'):format(item.p, shop.id))
        end
    end
end

lib.callback.register('kios:take', function(src, shopId, fid, index)
    if throttled(src) then return false, 'too_fast' end
    local shop = State.subscribedShop(src, shopId)
    if not shop then return false end

    local furn, spot = State.getSpot(shop, fid, index)
    if not furn or not spot or not spot.p or spot.q <= 0 then return false, 'out_of_stock' end

    local pos = Kios.spotWorld(furn, index)
    if not State.near(src, pos, Config.target.distance + 1.5) then return false end

    local cart = Carry.carts[src]
    if cart and cart.shop ~= shopId then
        Carry.returnToShelves(State.shops[cart.shop], Carry.takeAll(src))
        cart = nil
    end
    cart = cart or { shop = shopId, items = {} }
    if #cart.items >= Config.maxCarry then return false, 'hands_full' end

    State.setSpot(shop, furn, index, { p = spot.p, q = spot.q - 1 })
    cart.items[#cart.items + 1] = { p = spot.p, f = fid, s = index }
    Carry.carts[src] = cart
    Carry.sync(src)
    return true
end)

lib.callback.register('kios:drop', function(src, shopId, fid, index)
    if throttled(src) then return false, 'too_fast' end
    local shop = State.subscribedShop(src, shopId)
    if not shop then return false end

    local cart = Carry.carts[src]
    if not cart or cart.shop ~= shopId or #cart.items == 0 then return false, 'nothing_in_hands' end

    local furn, spot = State.getSpot(shop, fid, index)
    if not furn or not spot or not spot.p then return false, 'wrong_product' end

    local pos = Kios.spotWorld(furn, index)
    if not State.near(src, pos, Config.target.distance + 1.5) then return false end

    local def = Config.Products[spot.p]
    if spot.q >= def.capacity then return false, 'spot_full' end

    -- Prefer the unit that came from this exact spot, then the most recently taken one.
    local pick
    for i = #cart.items, 1, -1 do
        local item = cart.items[i]
        if item.p == spot.p then
            if item.f == fid and item.s == index then pick = i break end
            pick = pick or i
        end
    end
    if not pick then return false, 'wrong_product' end

    table.remove(cart.items, pick)
    if #cart.items == 0 then Carry.carts[src] = nil end
    Carry.sync(src)
    State.setSpot(shop, furn, index, { p = spot.p, q = spot.q + 1 })
    return true
end)

---Called when a player holding unpaid products is no longer inside the shop.
function Carry.leftShop(src)
    local cart = Carry.carts[src]
    if not cart then return end
    local shop = State.shops[cart.shop]
    local items = Carry.takeAll(src)
    if not shop or #items == 0 then return end

    if Config.theft.mode ~= 'keep' then
        Carry.returnToShelves(shop, items)
        State.notify(src, 'items_returned', 'inform')
        return
    end

    local kept, value = {}, 0
    for _, item in ipairs(items) do
        local def = Config.Products[item.p]
        if def and exports.ox_inventory:CanCarryItem(src, def.item, 1) and exports.ox_inventory:AddItem(src, def.item, 1) then
            kept[#kept + 1] = item.p
            value = value + Kios.price(shop.prices, item.p)
        else
            State.restockOne(shop, item.p, item.f, item.s)
        end
    end

    if #kept > 0 then
        State.notify(src, 'left_with_items', 'warning')
        DB.log(shop.id, 'theft', value, Bridge.getIdentifier(src), Bridge.getName(src), { items = kept })
        -- Hook for dispatch / police alerts: AddEventHandler('kios:theft', function(shopId, src, items, value) end)
        TriggerEvent('kios:theft', shop.id, src, kept, value)
    end
end

function Carry.dropped(src)
    lastAction[src] = nil
    local cart = Carry.carts[src]
    if not cart then return end
    Carry.carts[src] = nil
    local shop = State.shops[cart.shop]
    if shop then Carry.returnToShelves(shop, cart.items) end
end
