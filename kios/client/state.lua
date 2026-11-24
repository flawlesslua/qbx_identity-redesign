--[[
    Client copy of the shop the player is standing in: furniture, spots, registers and the
    local props that represent them. Everything is rebuilt from the server snapshot on entry.
]]

Shop = {
    current = nil,
    generation = 0,
}

local hiddenModels = {}

local function alive(gen)
    return Shop.current ~= nil and Shop.generation == gen
end

-- Spots ---------------------------------------------------------------------------------------

local function despawnSpot(furn, index)
    Props.deleteAll(furn.spotProps[index])
    furn.spotProps[index] = nil
end

local function spawnSpot(furn, index)
    despawnSpot(furn, index)
    local spot = furn.spots[index]
    if not spot or not spot.p or spot.q <= 0 then return end
    local def = Config.Products[spot.p]
    if not def then return end

    local gen = Shop.generation
    local pos, heading = furn.spotPos[index], furn.spotHeading[index]
    local objs = {}
    furn.spotProps[index] = objs
    for k = 1, math.min(spot.q, def.stack.count) do
        local offset = def.stack.step * (k - 1) + vec3(0.0, 0.0, def.zOffset)
        local obj = Props.spawn(def.model, Kios.toWorld(pos, heading, offset), heading, { rot = def.rot })
        if not alive(gen) or furn.spotProps[index] ~= objs then
            Props.delete(obj)
            return
        end
        objs[k] = obj
    end
end

-- Furniture -----------------------------------------------------------------------------------

function Shop.addFurniture(data)
    local shop = Shop.current
    if not shop then return end
    local def = Config.Furniture[data.type]
    if not def then return end
    if shop.furniture[data.id] then Shop.removeFurniture(data.id) end

    local furn = {
        id = data.id,
        type = data.type,
        coords = data.coords,
        heading = data.heading,
        spots = {},
        spotPos = {},
        spotHeading = {},
        spotProps = {},
    }
    for _, s in ipairs(data.spots or {}) do
        furn.spots[s.i] = { p = s.p, q = s.q }
    end
    for index in ipairs(def.spots) do
        furn.spotPos[index], furn.spotHeading[index] = Kios.spotWorld(furn, index)
    end
    shop.furniture[furn.id] = furn
    Target.dirty = true

    local gen = Shop.generation
    furn.entity = Props.spawn(def.model, furn.coords, furn.heading, { collision = true })
    if not alive(gen) or shop.furniture[furn.id] ~= furn then
        Props.delete(furn.entity)
        return
    end
    if furn.entity then shop.entities[furn.entity] = furn.id end

    for index in ipairs(def.spots) do
        spawnSpot(furn, index)
        if not alive(gen) then return end
    end
end

function Shop.removeFurniture(fid)
    local shop = Shop.current
    local furn = shop and shop.furniture[fid]
    if not furn then return end
    for index in pairs(furn.spotProps) do despawnSpot(furn, index) end
    if furn.entity then shop.entities[furn.entity] = nil end
    Props.delete(furn.entity)
    shop.furniture[fid] = nil
    if shop.registers[fid] then Shop.setRegister(fid, nil) end
    Target.dirty = true
end

function Shop.updateSpot(fid, index, data)
    local shop = Shop.current
    local furn = shop and shop.furniture[fid]
    if not furn then return end
    furn.spots[index] = data or nil
    spawnSpot(furn, index)
end

-- Registers -----------------------------------------------------------------------------------

function Shop.setRegister(fid, data)
    local shop = Shop.current
    if not shop then return end
    local reg = shop.registers[fid]
    if reg then
        Props.deleteAll(reg.counterProps)
        Props.delete(reg.bagProp)
    end
    if not data then
        shop.registers[fid] = nil
        Checkout.onRegister(fid, nil)
        return
    end

    reg = data
    reg.counterProps = {}
    shop.registers[fid] = reg
    Checkout.onRegister(fid, reg)

    local furn = shop.furniture[fid]
    local def = furn and Config.Furniture[furn.type].register
    if not def then return end
    local gen = Shop.generation

    if reg.stage == 'scanning' or reg.stage == 'pay' then
        for i, product in ipairs(reg.items) do
            local slot = def.counter[i]
            local pdef = Config.Products[product]
            if slot and pdef then
                local pos = Kios.toWorld(furn.coords, furn.heading, slot + vec3(0.0, 0.0, pdef.zOffset))
                local obj = Props.spawn(pdef.model, pos, furn.heading + 90.0, { rot = pdef.rot })
                if not alive(gen) or shop.registers[fid] ~= reg then return Props.delete(obj) end
                reg.counterProps[i] = obj
            end
        end
    end

    if reg.bag then
        local pos = Kios.toWorld(furn.coords, furn.heading, def.bag)
        local obj = Props.spawn(Config.checkout.bagModel, pos, furn.heading)
        if not alive(gen) or shop.registers[fid] ~= reg then return Props.delete(obj) end
        reg.bagProp = obj
    end
end

-- Enter / exit --------------------------------------------------------------------------------

function Shop.enter(cfg)
    if Shop.current and Shop.current.id == cfg.id then return end
    if Shop.current then Shop.exit() end

    Shop.generation = Shop.generation + 1
    local gen = Shop.generation
    local snap
    for _ = 1, 3 do
        snap = lib.callback.await('kios:subscribe', false, cfg.id)
        if snap or Shop.generation ~= gen then break end
        Wait(2000)
    end
    if not snap or Shop.generation ~= gen then return end

    Shop.current = {
        id = cfg.id,
        cfg = cfg,
        label = snap.label,
        open = snap.open,
        prices = snap.prices or {},
        isAdmin = snap.isAdmin,
        furniture = {},
        registers = {},
        entities = {},
    }

    local radius = math.max(cfg.zone.size.x, cfg.zone.size.y) / 2 + 2.0
    for _, name in ipairs(cfg.hideModels or {}) do
        local hash = joaat(name)
        CreateModelHide(cfg.zone.center.x, cfg.zone.center.y, cfg.zone.center.z, radius, hash, true)
        hiddenModels[#hiddenModels + 1] = { hash = hash, radius = radius, center = cfg.zone.center }
    end

    Target.start()

    for _, furn in ipairs(snap.furniture) do
        Shop.addFurniture(furn)
        if not alive(gen) then return end
    end
    for _, reg in ipairs(snap.registers) do
        Shop.setRegister(reg.fid, reg)
        if not alive(gen) then return end
    end
end

function Shop.exit()
    local shop = Shop.current
    Shop.generation = Shop.generation + 1
    if not shop then return end
    Shop.current = nil

    TriggerServerEvent('kios:unsubscribe', shop.id)
    Target.stop()
    Checkout.clear()

    for _, furn in pairs(shop.furniture) do
        for _, objs in pairs(furn.spotProps) do Props.deleteAll(objs) end
        Props.delete(furn.entity)
    end
    for _, reg in pairs(shop.registers) do
        Props.deleteAll(reg.counterProps)
        Props.delete(reg.bagProp)
    end

    for _, h in ipairs(hiddenModels) do
        RemoveModelHide(h.center.x, h.center.y, h.center.z, h.radius, h.hash, false)
    end
    hiddenModels = {}
end

-- Server deltas -------------------------------------------------------------------------------

local function forCurrent(shopId)
    return Shop.current and Shop.current.id == shopId
end

RegisterNetEvent('kios:c:spot', function(shopId, fid, index, data)
    if forCurrent(shopId) then Shop.updateSpot(fid, index, data) end
end)

RegisterNetEvent('kios:c:furnAdd', function(shopId, data)
    if forCurrent(shopId) then Shop.addFurniture(data) end
end)

RegisterNetEvent('kios:c:furnDel', function(shopId, fid)
    if forCurrent(shopId) then Shop.removeFurniture(fid) end
end)

RegisterNetEvent('kios:c:register', function(shopId, fid, data)
    if forCurrent(shopId) then Shop.setRegister(fid, data) end
end)
