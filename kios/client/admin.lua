--[[
    Admin tools (all behind the /kios command, ACE restricted):
        /kios place <type>  ghost placement of a furniture
        /kios remove        remove the furniture you aim at
        /kios stock         toggle stock mode: aim at any spot and press Enter to edit it
        /kios spots         spot editor for the furniture you aim at (copies config to clipboard)
        /kios fill          fill every assigned spot (server side)
]]

Admin = {
    stock = false,
    toolActive = false,
}

local keys = Config.keys
local SCROLL_UP, SCROLL_DOWN, SHIFT = 15, 14, 21
local blockControls = { 14, 15, 16, 17, 24, 25, 37, 44, 45, 140, 141, 142, 257, 263 }

local function notify(key, kind, ...)
    lib.notify({ description = locale(key, ...), type = kind or 'inform' })
end

local function block()
    for _, control in ipairs(blockControls) do DisableControlAction(0, control, true) end
end

local function aimedFurniture()
    local shop = Shop.current
    if not shop then return end
    local hit, _, entity = Props.camRay(16, 8.0)
    if not hit or not entity or entity == 0 then return end
    local fid = shop.entities[entity]
    return fid and shop.furniture[fid]
end

-- Placement -----------------------------------------------------------------------------------

local function place(furnType)
    local shop = Shop.current
    local def = Config.Furniture[furnType]
    if not shop or not def or Admin.toolActive then return end

    local hash, valid = Props.model(def.model)
    if not valid then return notify('admin_model_missing', 'error', def.model) end
    if not pcall(lib.requestModel, hash, 5000) then return notify('admin_model_missing', 'error', def.model) end

    Admin.toolActive = true
    local pedPos = GetEntityCoords(cache.ped)
    local ghost = CreateObjectNoOffset(hash, pedPos.x, pedPos.y, pedPos.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAlpha(ghost, 180, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityDrawOutline(ghost, true)
    SetEntityDrawOutlineShader(1)

    local heading = Kios.normalizeHeading(math.floor(GetEntityHeading(cache.ped) / 15.0 + 0.5) * 15.0)
    local coords = pedPos

    Nui.send('hint', {
        title = locale('place_title'),
        subtitle = def.label,
        keys = {
            { key = keys.primary.label, label = locale('place_place') },
            { key = 'Wheel', label = locale('place_rotate') },
            { key = 'Shift', label = locale('place_fine') },
            { key = keys.cancel.label, label = locale('place_cancel') },
        },
    })

    while Admin.toolActive and Shop.current == shop do
        block()
        local hit, hitCoords = Props.camRay(1, 12.0, ghost)
        if hit then coords = hitCoords end

        local step = IsControlPressed(0, SHIFT) and 1.0 or 15.0
        if IsDisabledControlJustPressed(0, SCROLL_UP) then heading = Kios.normalizeHeading(heading + step) end
        if IsDisabledControlJustPressed(0, SCROLL_DOWN) then heading = Kios.normalizeHeading(heading - step) end

        SetEntityCoordsNoOffset(ghost, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(ghost, heading)

        local valid = hit and Kios.inZone(coords, shop.cfg.zone, 0.0)
        if valid then
            SetEntityDrawOutlineColor(80, 220, 120, 255)
        else
            SetEntityDrawOutlineColor(235, 70, 70, 255)
        end

        if IsControlJustPressed(0, keys.primary.control) and valid then
            local ok = lib.callback.await('kios:admin:place', false, shop.id, furnType, coords, heading)
            notify(ok and 'admin_placed' or 'admin_failed', ok and 'success' or 'error')
            break
        elseif IsControlJustPressed(0, keys.cancel.control) then
            break
        end
        Wait(0)
    end

    DeleteEntity(ghost)
    Nui.send('hint', false)
    Admin.toolActive = false
end

-- Remove --------------------------------------------------------------------------------------

local function remove()
    local furn = aimedFurniture()
    if not furn then return notify('admin_aim_furniture', 'error') end
    local def = Config.Furniture[furn.type]
    local answer = lib.alertDialog({
        header = locale('admin_remove_title'),
        content = locale('admin_remove_confirm', def.label),
        centered = true,
        cancel = true,
    })
    if answer ~= 'confirm' then return end
    local ok = lib.callback.await('kios:admin:remove', false, Shop.current.id, furn.id)
    notify(ok and 'admin_removed' or 'admin_failed', ok and 'success' or 'error')
end

-- Spot editor ---------------------------------------------------------------------------------

local function fmt(n)
    local s = ('%.3f'):format(n):gsub('%.?0+$', ''):gsub('^%-0$', '0')
    return s
end

local function spotsToLua(spots)
    local out = { 'spots = {' }
    for _, s in ipairs(spots) do
        out[#out + 1] = ('    { offset = vec3(%s, %s, %s), heading = %s },'):format(
            fmt(s.offset.x), fmt(s.offset.y), fmt(s.offset.z), fmt(s.heading))
    end
    out[#out + 1] = '},'
    return table.concat(out, '\n')
end

local function spotEditor()
    if Admin.toolActive then return end
    local furn = aimedFurniture()
    if not furn then return notify('admin_aim_furniture', 'error') end
    local def = Config.Furniture[furn.type]

    local spots = {}
    for _, s in ipairs(def.spots) do
        spots[#spots + 1] = { offset = s.offset, heading = s.heading or 0.0 }
    end

    Admin.toolActive = true
    local shop = Shop.current
    local function hint()
        Nui.send('hint', {
            title = locale('spots_title'),
            subtitle = def.label,
            counter = #spots,
            keys = {
                { key = keys.primary.label, label = locale('spots_add') },
                { key = 'Shift', label = locale('spots_rotate') },
                { key = keys.cancel.label, label = locale('spots_undo') },
                { key = keys.confirm.label, label = locale('spots_finish') },
            },
        })
    end
    hint()

    while Admin.toolActive and Shop.current == shop and shop.furniture[furn.id] == furn do
        block()
        for _, s in ipairs(spots) do
            local p = Kios.toWorld(furn.coords, furn.heading, s.offset)
            DrawMarker(28, p.x, p.y, p.z, 0, 0, 0, 0, 0, 0, 0.025, 0.025, 0.025, 255, 255, 255, 220, false, false, 2, false, nil, nil, false)
        end

        local hit, coords, entity = Props.camRay(17, 6.0)
        local onFurniture = hit and entity == furn.entity
        if onFurniture then
            DrawMarker(28, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, 0.035, 0.035, 0.035, 80, 220, 120, 230, false, false, 2, false, nil, nil, false)
        end

        if onFurniture and IsControlJustPressed(0, keys.primary.control) then
            -- Product faces the player; snap to 90° unless Shift is held.
            local h = Kios.normalizeHeading(GetEntityHeading(cache.ped) + 180.0 - furn.heading)
            if not IsControlPressed(0, SHIFT) then h = Kios.normalizeHeading(math.floor(h / 90.0 + 0.5) * 90.0) end
            local o = Kios.toLocal(furn.coords, furn.heading, coords)
            spots[#spots + 1] = { offset = vec3(Kios.round(o.x, 3), Kios.round(o.y, 3), Kios.round(o.z, 3)), heading = h }
            hint()
        elseif IsControlJustPressed(0, keys.cancel.control) and #spots > 0 then
            spots[#spots] = nil
            hint()
        elseif IsControlJustPressed(0, keys.confirm.control) then
            local text = spotsToLua(spots)
            print(('[kios] spots for %s (%s):\n%s'):format(furn.type, def.model, text))
            lib.setClipboard(text)
            notify('spots_copied', 'success', #spots)
            break
        end
        Wait(0)
    end

    Nui.send('hint', false)
    Admin.toolActive = false
end

-- Stock menu ----------------------------------------------------------------------------------

function Admin.editSpot(furn, index)
    local shop = Shop.current
    if not shop or not shop.isAdmin then return end
    local def = Config.Furniture[furn.type]
    local spot = furn.spots[index]

    local function run(action, product)
        local ok = lib.callback.await('kios:admin:spot', false, shop.id, furn.id, index, action, product)
        if not ok then notify('admin_failed', 'error') end
    end

    local productOptions = {}
    for key, p in pairs(Config.Products) do
        productOptions[#productOptions + 1] = {
            title = p.label,
            description = ('%s · %s · x%s'):format(p.category or '-', Kios.money(p.price), p.capacity),
            onSelect = function() run('set', key) end,
        }
    end
    table.sort(productOptions, function(a, b) return a.title < b.title end)

    lib.registerContext({
        id = 'kios_stock_products',
        title = locale('stock_set'),
        menu = 'kios_stock',
        options = productOptions,
    })

    local options = {
        { title = locale('stock_set'), description = locale('stock_set_desc'), menu = 'kios_stock_products', arrow = true },
    }
    if spot and spot.p then
        options[#options + 1] = { title = locale('stock_fill'), onSelect = function() run('fill') end }
        options[#options + 1] = { title = locale('stock_empty'), onSelect = function() run('empty') end }
        options[#options + 1] = { title = locale('stock_unassign'), onSelect = function() run('unassign') end }
    end

    lib.registerContext({
        id = 'kios_stock',
        title = locale('stock_menu_title', def.label, index),
        options = options,
    })
    lib.showContext('kios_stock')
end

-- Events from the /kios command ---------------------------------------------------------------

RegisterNetEvent('kios:c:admin:place', function(furnType)
    place(furnType)
end)

RegisterNetEvent('kios:c:admin:remove', function()
    remove()
end)

RegisterNetEvent('kios:c:admin:spots', function()
    spotEditor()
end)

RegisterNetEvent('kios:c:admin:stock', function()
    Admin.stock = not Admin.stock
    notify(Admin.stock and 'admin_stock_on' or 'admin_stock_off', 'inform')
end)
