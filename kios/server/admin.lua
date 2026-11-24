local function shopOf(src)
    local id = State.inShop[src]
    return id and State.shops[id]
end

local function typeList()
    local list = {}
    for key in pairs(Config.Furniture) do list[#list + 1] = key end
    table.sort(list)
    return table.concat(list, ', ')
end

lib.addCommand('kios', {
    help = locale('admin_help'),
    params = {
        { name = 'action', type = 'string', help = locale('admin_action') },
        { name = 'arg', type = 'string', help = locale('admin_arg'), optional = true },
    },
    restricted = Config.adminGroup,
}, function(src, args)
    local action = args.action

    if action == 'types' then
        return State.notify(src, 'admin_types', 'inform', typeList())
    end

    local shop = shopOf(src)
    if not shop then return State.notify(src, 'admin_not_in_shop', 'error') end

    if action == 'place' then
        if not args.arg or not Config.Furniture[args.arg] then
            return State.notify(src, 'admin_unknown_type', 'error', tostring(args.arg))
        end
        TriggerClientEvent('kios:c:admin:place', src, args.arg)
    elseif action == 'remove' then
        TriggerClientEvent('kios:c:admin:remove', src)
    elseif action == 'stock' then
        TriggerClientEvent('kios:c:admin:stock', src)
    elseif action == 'spots' then
        TriggerClientEvent('kios:c:admin:spots', src)
    elseif action == 'fill' then
        local filled = 0
        for _, furn in pairs(shop.furniture) do
            for index, spot in pairs(furn.spots) do
                local def = Config.Products[spot.p]
                if def and spot.q < def.capacity then
                    State.setSpot(shop, furn, index, { p = spot.p, q = def.capacity })
                    filled = filled + 1
                end
            end
        end
        State.notify(src, 'admin_filled', 'success', filled)
    else
        State.notify(src, 'admin_help', 'inform')
    end
end)

lib.callback.register('kios:admin:place', function(src, shopId, furnType, coords, heading)
    if not State.isAdmin(src) then return false end
    local shop = State.subscribedShop(src, shopId)
    local def = Config.Furniture[furnType]
    if not shop or not def or type(coords) ~= 'vector3' then return false end
    if not Kios.inZone(coords, shop.cfg.zone, 0.5) then return false end

    local furn = {
        type = furnType,
        coords = coords,
        heading = Kios.normalizeHeading(tonumber(heading) or 0.0),
        spots = {},
    }
    furn.id = DB.insertFurniture(shop.id, furn)
    if not furn.id then return false end

    shop.furniture[furn.id] = furn
    State.initRegister(shop, furn)
    State.emit(shop, 'kios:c:furnAdd', State.serializeFurniture(furn))
    if shop.registers[furn.id] then Checkout.emit(shop, shop.registers[furn.id]) end
    DB.log(shop.id, 'furniture_add', 0, Bridge.getIdentifier(src), Bridge.getName(src), { id = furn.id, type = furnType })
    return true
end)

lib.callback.register('kios:admin:remove', function(src, shopId, fid)
    if not State.isAdmin(src) then return false end
    local shop = State.subscribedShop(src, shopId)
    local furn = shop and shop.furniture[fid]
    if not furn then return false end

    local reg = shop.registers[fid]
    if reg then Checkout.release(shop, reg) end

    shop.furniture[fid] = nil
    shop.registers[fid] = nil
    State.forget(fid)
    DB.deleteFurniture(fid)
    State.emit(shop, 'kios:c:furnDel', fid)
    DB.log(shop.id, 'furniture_remove', 0, Bridge.getIdentifier(src), Bridge.getName(src), { id = fid, type = furn.type })
    return true
end)

---action: 'set' (product), 'fill', 'empty', 'unassign'
lib.callback.register('kios:admin:spot', function(src, shopId, fid, index, action, product)
    if not State.isAdmin(src) then return false end
    local shop = State.subscribedShop(src, shopId)
    if not shop then return false end
    local furn, spot = State.getSpot(shop, fid, index)
    if not furn then return false end

    if action == 'set' then
        local def = Config.Products[product]
        if not def then return false end
        State.setSpot(shop, furn, index, { p = product, q = def.capacity })
    elseif action == 'fill' and spot and spot.p then
        State.setSpot(shop, furn, index, { p = spot.p, q = Config.Products[spot.p].capacity })
    elseif action == 'empty' and spot and spot.p then
        State.setSpot(shop, furn, index, { p = spot.p, q = 0 })
    elseif action == 'unassign' then
        State.setSpot(shop, furn, index, nil)
    else
        return false
    end
    return true
end)
