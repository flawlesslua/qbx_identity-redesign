lib.locale()

Kios = Kios or {}

local rad, sin, cos, abs = math.rad, math.sin, math.cos, math.abs

---Converts a furniture-local offset (x = right, y = forward, z = up) to world coordinates.
---Matches GetOffsetFromEntityInWorldCoords for an upright entity.
---@param origin vector3
---@param heading number degrees
---@param offset vector3
---@return vector3
function Kios.toWorld(origin, heading, offset)
    local h = rad(heading)
    local c, s = cos(h), sin(h)
    return vec3(
        origin.x + offset.x * c - offset.y * s,
        origin.y + offset.x * s + offset.y * c,
        origin.z + offset.z
    )
end

---Inverse of Kios.toWorld.
---@param origin vector3
---@param heading number degrees
---@param world vector3
---@return vector3
function Kios.toLocal(origin, heading, world)
    local h = rad(heading)
    local c, s = cos(h), sin(h)
    local dx, dy = world.x - origin.x, world.y - origin.y
    return vec3(dx * c + dy * s, -dx * s + dy * c, world.z - origin.z)
end

---@param point vector3
---@param zone { center: vector3, size: vector3, rotation?: number }
---@param margin? number
---@return boolean
function Kios.inZone(point, zone, margin)
    margin = margin or 0.0
    local l = Kios.toLocal(zone.center, zone.rotation or 0.0, point)
    return abs(l.x) <= zone.size.x / 2 + margin
        and abs(l.y) <= zone.size.y / 2 + margin
        and abs(l.z) <= zone.size.z / 2 + margin
end

function Kios.round(n, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(n * m + 0.5) / m
end

function Kios.normalizeHeading(h)
    h = h % 360.0
    if h < 0 then h = h + 360.0 end
    return h
end

---Builds a list of spots laid out on a grid. Handy for symmetrical shelves.
---@param def { sides: { y: number, heading: number }[], levels: number[], columns: number[] }
---@return { offset: vector3, heading: number }[]
function Kios.grid(def)
    local spots = {}
    for _, side in ipairs(def.sides) do
        for _, z in ipairs(def.levels) do
            for _, x in ipairs(def.columns) do
                spots[#spots + 1] = { offset = vec3(x, side.y, z), heading = side.heading or 0.0 }
            end
        end
    end
    return spots
end

---World position and heading of a spot on a placed furniture.
---@param furn { coords: vector3, heading: number, type: string }
---@param index integer
---@return vector3?, number?
function Kios.spotWorld(furn, index)
    local def = Config.Furniture[furn.type]
    local spot = def and def.spots and def.spots[index]
    if not spot then return end
    return Kios.toWorld(furn.coords, furn.heading, spot.offset), Kios.normalizeHeading(furn.heading + (spot.heading or 0.0))
end

---Price of a product in a shop (per-shop overrides arrive with the management phase).
---@param shopPrices table<string, number>?
---@param product string
---@return integer
function Kios.price(shopPrices, product)
    if shopPrices and shopPrices[product] then return shopPrices[product] end
    local def = Config.Products[product]
    return def and def.price or 0
end

function Kios.money(amount)
    return ('%s%s'):format(Config.currency, amount)
end
