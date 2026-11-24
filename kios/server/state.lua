State = {
    ready = false,
    shops = {},      -- [shopId] = shop
    inShop = {},     -- [src] = shopId (subscribed players)
}

local dirty = {}     -- [furnitureId] = furniture

function State.isAdmin(src)
    return IsPlayerAceAllowed(src, 'command.kios')
end

function State.notify(src, key, kind, ...)
    TriggerClientEvent('ox_lib:notify', src, {
        description = locale(key, ...),
        type = kind or 'inform',
    })
end

function State.pedCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    return GetEntityCoords(ped)
end

function State.near(src, pos, maxDist)
    local coords = State.pedCoords(src)
    return coords ~= nil and #(coords - pos) <= maxDist
end

---@return table? shop
function State.subscribedShop(src, shopId)
    if State.inShop[src] ~= shopId then return end
    return State.shops[shopId]
end

function State.initRegister(shop, furn)
    local def = Config.Furniture[furn.type]
    if not def.register then return end
    shop.registers[furn.id] = {
        fid = furn.id,
        mode = def.register.mode or 'self',
        stage = 'idle',     -- idle | scanning | pay | paid
        customer = nil,
        items = {},         -- { p = product, f = furnitureId, s = spotIndex }
        scanned = 0,
        total = 0,
        session = 0,
        bag = nil,          -- { owner = src, items = {...}, total = n }
    }
end

function State.load()
    for _, cfg in ipairs(Config.Shops) do
        local meta = DB.ensureShop(cfg.id)
        local shop = {
            id = cfg.id,
            cfg = cfg,
            owner = meta.owner,
            ownerName = meta.ownerName,
            balance = meta.balance,
            open = meta.open,
            prices = meta.prices or {},
            furniture = {},
            registers = {},
            subscribers = {},
        }
        for _, furn in ipairs(DB.loadFurniture(cfg.id)) do
            if Config.Furniture[furn.type] then
                shop.furniture[furn.id] = furn
                State.initRegister(shop, furn)
            else
                print(('[kios] ^3furniture %s in %s has unknown type "%s", skipped^0'):format(furn.id, cfg.id, furn.type))
            end
        end
        State.shops[cfg.id] = shop
    end
    State.ready = true
end

-- Serialisation -------------------------------------------------------------------------------

function State.serializeFurniture(furn)
    local spots = {}
    for index, spot in pairs(furn.spots) do
        spots[#spots + 1] = { i = index, p = spot.p, q = spot.q }
    end
    return { id = furn.id, type = furn.type, coords = furn.coords, heading = furn.heading, spots = spots }
end

function State.serializeRegister(reg)
    local items = {}
    for i, item in ipairs(reg.items) do items[i] = item.p end
    local bag = false
    if reg.bag then
        local bagItems = {}
        for i, item in ipairs(reg.bag.items) do bagItems[i] = item.p end
        bag = { owner = reg.bag.owner, items = bagItems, total = reg.bag.total }
    end
    return {
        fid = reg.fid,
        mode = reg.mode,
        stage = reg.stage,
        customer = reg.customer or false,
        items = items,
        scanned = reg.scanned,
        total = reg.total,
        bag = bag,
    }
end

function State.snapshot(shop, src)
    local furniture, registers = {}, {}
    for _, furn in pairs(shop.furniture) do
        furniture[#furniture + 1] = State.serializeFurniture(furn)
    end
    for _, reg in pairs(shop.registers) do
        registers[#registers + 1] = State.serializeRegister(reg)
    end
    return {
        id = shop.id,
        label = shop.cfg.label,
        open = shop.open,
        prices = shop.prices,
        furniture = furniture,
        registers = registers,
        isAdmin = State.isAdmin(src),
    }
end

-- Broadcasting --------------------------------------------------------------------------------

function State.emit(shop, event, ...)
    for src in pairs(shop.subscribers) do
        TriggerClientEvent(event, src, shop.id, ...)
    end
end

function State.subscribe(src, shop)
    local current = State.inShop[src]
    if current and current ~= shop.id and State.shops[current] then
        State.shops[current].subscribers[src] = nil
    end
    shop.subscribers[src] = true
    State.inShop[src] = shop.id
end

function State.unsubscribe(src)
    local current = State.inShop[src]
    if current and State.shops[current] then
        State.shops[current].subscribers[src] = nil
    end
    State.inShop[src] = nil
end

-- Spots ---------------------------------------------------------------------------------------

function State.getSpot(shop, fid, index)
    local furn = shop.furniture[fid]
    if not furn then return end
    local def = Config.Furniture[furn.type]
    if not def or not def.spots[index] then return end
    return furn, furn.spots[index]
end

---@param data { p: string, q: integer }|nil
function State.setSpot(shop, furn, index, data)
    furn.spots[index] = data
    dirty[furn.id] = furn
    State.emit(shop, 'kios:c:spot', furn.id, index, data or false)
end

---Puts one unit back on the shelf: the spot it came from if possible, else any spot of the same
---product with room. Returns false when there is nowhere to put it.
function State.restockOne(shop, product, fid, index)
    local def = Config.Products[product]
    if not def then return false end
    local furn, spot = State.getSpot(shop, fid, index)
    if furn and spot and spot.p == product and spot.q < def.capacity then
        State.setSpot(shop, furn, index, { p = product, q = spot.q + 1 })
        return true
    end
    for _, f in pairs(shop.furniture) do
        for i, s in pairs(f.spots) do
            if s.p == product and s.q < def.capacity then
                State.setSpot(shop, f, i, { p = product, q = s.q + 1 })
                return true
            end
        end
    end
    return false
end

-- Money ---------------------------------------------------------------------------------------

---Sales go to the shop balance when the shop has an owner (management phase). Unowned shops
---behave like NPC shops and the money leaves the economy.
function State.addBalance(shop, amount)
    if not shop.owner then return end
    shop.balance = shop.balance + amount
    DB.saveBalance(shop.id, shop.balance)
end

-- Persistence ---------------------------------------------------------------------------------

function State.flush(sync)
    local list = {}
    for id, furn in pairs(dirty) do
        list[#list + 1] = furn
        dirty[id] = nil
    end
    if #list == 0 then return end
    if sync then
        DB.saveSpots(list)
    else
        DB.saveSpotsAsync(list)
    end
end

function State.forget(fid)
    dirty[fid] = nil
end
