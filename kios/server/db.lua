DB = {}

local schema = {
    [[CREATE TABLE IF NOT EXISTS `kios_shops` (
        `id` VARCHAR(64) NOT NULL,
        `owner` VARCHAR(100) NULL DEFAULT NULL,
        `owner_name` VARCHAR(100) NULL DEFAULT NULL,
        `balance` INT NOT NULL DEFAULT 0,
        `is_open` TINYINT(1) NOT NULL DEFAULT 1,
        `prices` LONGTEXT NULL DEFAULT NULL,
        `interior` LONGTEXT NULL DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`)
    )]],
    [[CREATE TABLE IF NOT EXISTS `kios_furniture` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `shop_id` VARCHAR(64) NOT NULL,
        `type` VARCHAR(64) NOT NULL,
        `x` DOUBLE NOT NULL,
        `y` DOUBLE NOT NULL,
        `z` DOUBLE NOT NULL,
        `heading` DOUBLE NOT NULL DEFAULT 0,
        `spots` LONGTEXT NULL DEFAULT NULL,
        PRIMARY KEY (`id`),
        INDEX `shop_id` (`shop_id`)
    )]],
    [[CREATE TABLE IF NOT EXISTS `kios_transactions` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `shop_id` VARCHAR(64) NOT NULL,
        `kind` VARCHAR(32) NOT NULL,
        `amount` INT NOT NULL DEFAULT 0,
        `actor` VARCHAR(100) NULL DEFAULT NULL,
        `actor_name` VARCHAR(100) NULL DEFAULT NULL,
        `data` LONGTEXT NULL DEFAULT NULL,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        INDEX `shop_id` (`shop_id`)
    )]],
}

function DB.migrate()
    for _, query in ipairs(schema) do
        MySQL.query.await(query)
    end
end

---Spots are stored as { ["1"] = { p = "product", q = 3 }, ... } so nil holes survive JSON.
local function encodeSpots(spots)
    local out = {}
    for index, spot in pairs(spots) do
        if spot and spot.p then
            out[tostring(index)] = { p = spot.p, q = spot.q or 0 }
        end
    end
    return json.encode(out)
end

local function decodeSpots(raw)
    local spots = {}
    local ok, data = pcall(json.decode, raw or '{}')
    if ok and type(data) == 'table' then
        for index, spot in pairs(data) do
            local i = tonumber(index)
            if i and type(spot) == 'table' and spot.p then
                spots[i] = { p = spot.p, q = tonumber(spot.q) or 0 }
            end
        end
    end
    return spots
end

function DB.ensureShop(id)
    MySQL.insert.await('INSERT IGNORE INTO `kios_shops` (`id`) VALUES (?)', { id })
    local row = MySQL.single.await('SELECT * FROM `kios_shops` WHERE `id` = ?', { id })
    local prices = row and row.prices and json.decode(row.prices) or {}
    return {
        owner = row and row.owner,
        ownerName = row and row.owner_name,
        balance = row and row.balance or 0,
        open = not row or row.is_open == 1 or row.is_open == true,
        prices = prices,
    }
end

function DB.loadFurniture(shopId)
    local rows = MySQL.query.await('SELECT * FROM `kios_furniture` WHERE `shop_id` = ?', { shopId }) or {}
    local list = {}
    for _, row in ipairs(rows) do
        list[#list + 1] = {
            id = row.id,
            type = row.type,
            coords = vec3(row.x, row.y, row.z),
            heading = row.heading + 0.0,
            spots = decodeSpots(row.spots),
        }
    end
    return list
end

function DB.insertFurniture(shopId, furn)
    return MySQL.insert.await(
        'INSERT INTO `kios_furniture` (`shop_id`, `type`, `x`, `y`, `z`, `heading`, `spots`) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { shopId, furn.type, furn.coords.x, furn.coords.y, furn.coords.z, furn.heading, encodeSpots(furn.spots) }
    )
end

function DB.deleteFurniture(id)
    MySQL.query.await('DELETE FROM `kios_furniture` WHERE `id` = ?', { id })
end

local function spotQueries(list)
    local queries = {}
    for i, furn in ipairs(list) do
        queries[i] = { query = 'UPDATE `kios_furniture` SET `spots` = ? WHERE `id` = ?', values = { encodeSpots(furn.spots), furn.id } }
    end
    return queries
end

---@param list { id: integer, spots: table }[]
function DB.saveSpots(list)
    if #list == 0 then return end
    MySQL.transaction.await(spotQueries(list))
end

---Fire-and-forget variant, safe to call while the resource is stopping.
function DB.saveSpotsAsync(list)
    if #list == 0 then return end
    MySQL.transaction(spotQueries(list))
end

function DB.saveBalance(shopId, balance)
    MySQL.update('UPDATE `kios_shops` SET `balance` = ? WHERE `id` = ?', { balance, shopId })
end

function DB.log(shopId, kind, amount, actor, actorName, data)
    MySQL.insert('INSERT INTO `kios_transactions` (`shop_id`, `kind`, `amount`, `actor`, `actor_name`, `data`) VALUES (?, ?, ?, ?, ?, ?)', {
        shopId, kind, amount or 0, actor, actorName, data and json.encode(data) or nil,
    })
end
