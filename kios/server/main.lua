CreateThread(function()
    DB.migrate()
    State.load()

    -- Carts do not survive a restart: clear what clients still show in hands.
    for _, id in ipairs(GetPlayers()) do
        Player(tonumber(id)).state:set('kiosCarry', nil, true)
    end

    print(('[kios] loaded %d shop(s)'):format(#Config.Shops))
end)

lib.callback.register('kios:subscribe', function(src, shopId)
    local timeout = GetGameTimer() + 10000
    while not State.ready and GetGameTimer() < timeout do Wait(100) end

    local shop = State.shops[shopId]
    if not shop then return end
    local coords = State.pedCoords(src)
    if not coords or not Kios.inZone(coords, shop.cfg.zone, 3.0) then return end

    State.subscribe(src, shop)
    return State.snapshot(shop, src)
end)

RegisterNetEvent('kios:unsubscribe', function(shopId)
    local src = source
    if State.inShop[src] == shopId then
        State.unsubscribe(src)
    end
end)

-- Every second: theft check, walk-away check, stale subscriptions.
CreateThread(function()
    while true do
        Wait(1000)
        if State.ready then
            for src, cart in pairs(Carry.carts) do
                local shop = State.shops[cart.shop]
                local coords = State.pedCoords(src)
                if shop and coords and not Kios.inZone(coords, shop.cfg.zone, Config.theft.margin) then
                    Carry.leftShop(src)
                end
            end

            Checkout.tick()

            for src, shopId in pairs(State.inShop) do
                local shop = State.shops[shopId]
                local coords = State.pedCoords(src)
                if not coords or not Kios.inZone(coords, shop.cfg.zone, 15.0) then
                    State.unsubscribe(src)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.saveInterval * 1000)
        if State.ready then State.flush(true) end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Checkout.dropped(src)
    Carry.dropped(src)
    State.unsubscribe(src)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    State.flush(false)
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    State.flush(false)
end)
