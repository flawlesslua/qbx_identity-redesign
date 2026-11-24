--[[
    Aim targeting. Instead of relying on prop collisions, every interactable is a known world
    point; the one closest to the camera ray (within Config.target.tolerance) is targeted.
    This keeps tiny products easy to aim at and costs a few multiplications per point.
]]

Target = {
    running = false,
    dirty = true,
    token = 0,
}

local candidates = {}
local current, currentSig, currentDesc
local trackLabel = Nui.tracker('targetPos')
local sqrt = math.sqrt

local controlFor = {}
for _, key in pairs(Config.keys) do controlFor[key.label] = key.control end

local function rebuild()
    candidates = {}
    local shop = Shop.current
    if not shop then return end
    for fid, furn in pairs(shop.furniture) do
        local def = Config.Furniture[furn.type]
        for index in ipairs(def.spots) do
            candidates[#candidates + 1] = {
                kind = 'spot', furn = furn, index = index,
                pos = furn.spotPos[index] + vec3(0.0, 0.0, 0.06),
            }
        end
        if def.register then
            candidates[#candidates + 1] = {
                kind = 'register', furn = furn, fid = fid,
                pos = Kios.toWorld(furn.coords, furn.heading, def.register.anchor),
            }
            candidates[#candidates + 1] = {
                kind = 'bag', furn = furn, fid = fid,
                pos = Kios.toWorld(furn.coords, furn.heading, def.register.bag + vec3(0.0, 0.0, 0.18)),
            }
        end
    end
    Target.dirty = false
end

local function visible(c)
    local shop = Shop.current
    if c.kind == 'spot' then
        local spot = c.furn.spots[c.index]
        return (spot and spot.p) or Admin.stock
    elseif c.kind == 'bag' then
        local reg = shop.registers[c.fid]
        return reg and reg.bag
    end
    return shop.registers[c.fid] ~= nil
end

local function describeSpot(c)
    local shop = Shop.current
    local keys = Config.keys
    local spot = c.furn.spots[c.index]

    if not spot or not spot.p then
        if not Admin.stock then return end
        return {
            label = locale('unknown_spot'), muted = true,
            actions = { { id = 'edit', key = keys.confirm.label, label = locale('edit') } },
        }
    end

    local def = Config.Products[spot.p]
    if not def then return end
    local actions = {}
    local desc = { price = Kios.money(Kios.price(shop.prices, spot.p)), actions = actions }

    if spot.q > 0 then
        desc.label, desc.qty = def.label, spot.q
        if Carry.count() < Config.maxCarry then
            actions[#actions + 1] = { id = 'take', key = keys.primary.label, label = locale('take') }
        end
    else
        desc.label, desc.muted = locale('spot', def.label), true
    end

    if spot.q < def.capacity and Carry.holding(spot.p) then
        actions[#actions + 1] = { id = 'drop', key = keys.secondary.label, label = locale('drop') }
    end
    if Admin.stock then
        actions[#actions + 1] = { id = 'edit', key = keys.confirm.label, label = locale('edit'), subtle = true }
    end
    return desc
end

local function describe(c)
    if c.kind == 'spot' then return describeSpot(c) end
    local reg = Shop.current.registers[c.fid]
    if not reg then return end
    if c.kind == 'register' then return Checkout.describeRegister(c.fid, reg) end
    return Checkout.describeBag(reg)
end

local function signature(desc)
    local parts = { desc.label or '', tostring(desc.qty), desc.price or '', tostring(desc.muted) }
    for _, a in ipairs(desc.actions or {}) do parts[#parts + 1] = a.id end
    return table.concat(parts, '|')
end

local function setTarget(c, desc)
    if not c or not desc then
        if current then
            current, currentSig, currentDesc = nil, nil, nil
            Nui.send('target', false)
            trackLabel(nil)
        end
        return
    end
    local sig = signature(desc)
    if c ~= current or sig ~= currentSig then
        current, currentSig = c, sig
        Nui.send('target', {
            label = desc.label,
            qty = desc.qty,
            price = desc.price,
            icon = desc.icon,
            muted = desc.muted,
            actions = desc.actions,
        })
    end
    currentDesc = desc
    trackLabel(c.pos)
end

local function dispatch(id, c)
    CreateThread(function()
        if id == 'take' then
            Carry.take(c.furn, c.index)
        elseif id == 'drop' then
            Carry.drop(c.furn, c.index)
        elseif id == 'edit' then
            Admin.editSpot(c.furn, c.index)
        elseif id == 'checkout' then
            Checkout.start(c.fid)
        elseif id == 'cash' or id == 'card' then
            Checkout.pay(c.fid, id)
        elseif id == 'cancel' then
            Checkout.cancel(c.fid)
        elseif id == 'take_bag' then
            Checkout.takeBag(c.fid)
        end
    end)
end

local function drawDot(pos, alpha, w, h)
    SetDrawOrigin(pos.x, pos.y, pos.z, 0)
    DrawSprite('kios_ui', 'dot', 0.0, 0.0, w, h, 0.0, 255, 255, 255, alpha)
    ClearDrawOrigin()
end

local function loop(token)
    local dotDistance = Config.target.dotDistance
    local maxDistance = Config.target.distance

    while Target.token == token and Shop.current do
        if Target.dirty then rebuild() end
        local ped = cache.ped

        if Admin.toolActive or IsPedInAnyVehicle(ped, false) or IsPauseMenuActive() or IsNuiFocused() then
            setTarget(nil)
            Wait(100)
        else
            local camPos, dir = Props.camera()
            local pedPos = GetEntityCoords(ped)
            local best, bestPerp = nil, Config.target.tolerance
            local dotW = 0.0052
            local dotH = dotW * GetAspectRatio(false)
            local dots = Config.target.dots

            for i = 1, #candidates do
                local c = candidates[i]
                if visible(c) then
                    local pos = c.pos
                    local dPed = #(pos - pedPos)
                    if dPed <= maxDistance then
                        local rx, ry, rz = pos.x - camPos.x, pos.y - camPos.y, pos.z - camPos.z
                        local t = rx * dir.x + ry * dir.y + rz * dir.z
                        if t > 0 then
                            local px, py, pz = rx - dir.x * t, ry - dir.y * t, rz - dir.z * t
                            local perp = sqrt(px * px + py * py + pz * pz)
                            if perp < bestPerp then best, bestPerp = c, perp end
                        end
                    end
                    if dots and c.kind == 'spot' and dPed <= dotDistance and c ~= current then
                        local alpha = math.floor(230 * (1.0 - math.max(0.0, dPed - dotDistance * 0.6) / (dotDistance * 0.4)))
                        if alpha > 10 then drawDot(pos, alpha, dotW, dotH) end
                    end
                end
            end

            local desc = best and describe(best)
            setTarget(desc and best or nil, desc)

            if current and currentDesc then
                for _, action in ipairs(currentDesc.actions or {}) do
                    local control = controlFor[action.key]
                    if control and IsControlJustPressed(0, control) then
                        dispatch(action.id, current)
                        break
                    end
                end
            end

            Checkout.frame()
            Wait(0)
        end
    end
    if Target.token == token then setTarget(nil) end
end

function Target.start()
    Target.dirty = true
    if Target.running then return end
    Target.running = true
    Target.token = Target.token + 1
    local token = Target.token
    CreateThread(function() loop(token) end)
end

function Target.stop()
    Target.running = false
    Target.token = Target.token + 1
    setTarget(nil)
end
