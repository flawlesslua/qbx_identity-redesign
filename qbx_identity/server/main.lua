local config = require 'config.server'

local slotCache = {}

CreateThread(function()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `license` VARCHAR(60) NOT NULL,
            `slots` TINYINT UNSIGNED NOT NULL,
            PRIMARY KEY (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]]):format(config.slotsTable))
end)

local function clamp(amount)
    if amount < 1 then return 1 end
    if amount > config.maxNumberOfCharacters then return config.maxNumberOfCharacters end
    return amount
end

local function getAllowedAmountOfCharacters(source)
    if slotCache[source] then return slotCache[source] end

    local license2 = GetPlayerIdentifierByType(source, 'license2')
    local license = GetPlayerIdentifierByType(source, 'license')
    local stored = MySQL.scalar.await(('SELECT MAX(slots) FROM `%s` WHERE license = ? OR license = ?'):format(config.slotsTable), {
        license2 or '',
        license or ''
    })

    local amount = clamp(stored or config.defaultNumberOfCharacters)
    slotCache[source] = amount

    return amount
end

local function mayDelete(source)
    if not config.deletePermission then return true end
    return IsPlayerAceAllowed(source, config.deletePermission)
end

AddEventHandler('playerDropped', function()
    slotCache[source] = nil
end)

local function trimmed(value, maxLength)
    if type(value) ~= 'string' then return nil end

    value = value:gsub('^%s+', ''):gsub('%s+$', '')

    if value == '' or #value > maxLength then return nil end

    return value
end

local function wordSafe(value)
    if value:find('[^%a ]') then return false end

    local words = 0

    for _ in value:gmatch('%S+') do
        words += 1
    end

    return words > 0 and words <= config.maxWords
end

local function capitalize(value)
    return (value:gsub("(%w)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function sanitizeNewCharInfo(data)
    local firstname = trimmed(data.firstname, config.maxTextLength)
    local lastname = trimmed(data.lastname, config.maxTextLength)
    local nationality = trimmed(data.nationality, config.maxTextLength)
    local birthdate = trimmed(data.birthdate, config.maxTextLength)
    local gender = tonumber(data.gender)
    local height = tonumber(data.height)

    if not firstname or not lastname or not nationality or not birthdate or not gender or not height then
        return nil
    end

    if not wordSafe(firstname) or not wordSafe(lastname) or not wordSafe(nationality) then
        return nil
    end

    if config.profanityWords[firstname:lower()] or config.profanityWords[lastname:lower()] then
        return nil
    end

    if not birthdate:match('^%d%d%d%d%-%d%d%-%d%d$') then
        return nil
    end

    local year = tonumber(birthdate:sub(1, 4))

    if year < config.minYear or year > config.maxYear then
        return nil
    end

    gender = math.floor(gender)

    if gender ~= 0 and gender ~= 1 then
        return nil
    end

    height = math.floor(height)

    if height < config.minHeight or height > config.maxHeight then
        return nil
    end

    return {
        firstname = capitalize(firstname),
        lastname = capitalize(lastname),
        nationality = capitalize(nationality),
        birthdate = birthdate,
        gender = gender,
        height = height,
        backstory = trimmed(data.backstory, config.maxBackstoryLength) or 'placeholder backstory',
    }
end

local function getNextCid(existingCharacters)
    local lastCharacter = existingCharacters[#existingCharacters]
    return (lastCharacter and lastCharacter.charinfo.cid or 0) + 1
end

lib.callback.register('qbx_core:server:getCharacters', function(source)
    return exports.qbx_core:GetCharacters(source), getAllowedAmountOfCharacters(source), mayDelete(source)
end)

lib.callback.register('qbx_core:server:getPreviewPedData', function(_, citizenId)
    local ped = exports.qbx_core:GetCharacterSkin(citizenId)
    if not ped then return end

    return ped.skin, ped.model
end)

lib.callback.register('qbx_core:server:loadCharacter', function(source, citizenId)
    local success = exports.qbx_core:Login(source, citizenId)

    if success then
        TriggerEvent('qbx_identity:characterChosen', source)
    end

    return success
end)

lib.callback.register('qbx_core:server:createCharacter', function(source, data)
    if type(data) ~= 'table' then return end

    local existingCharacters = exports.qbx_core:GetCharacters(source)

    if #existingCharacters >= getAllowedAmountOfCharacters(source) then
        return
    end

    local charinfo = sanitizeNewCharInfo(data)
    if not charinfo then return end

    charinfo.cid = getNextCid(existingCharacters)

    local newData = exports.qbx_core:CreateCharacter(source, charinfo)
    if not newData then return end

    TriggerEvent('qbx_identity:characterChosen', source)
    lib.print.info(('%s has created a character'):format(GetPlayerName(source)))

    return newData
end)

RegisterNetEvent('qbx_core:server:deleteCharacter', function(citizenId)
    local src = source

    if not mayDelete(src) then
        exports.qbx_core:Notify(src, locale('error.no_access'), 'error')
        return
    end

    if exports.qbx_core:DeleteOwnedCharacter(src, citizenId) then
        exports.qbx_core:Notify(src, locale('success.character_deleted'), 'success')
    end
end)

RegisterNetEvent('qbx_identity:server:beginSpawnSelection', function()
    local src = source
    local state = Player(src)?.state

    if state then
        state:set('inProperty', true, true)
    end
end)

RegisterNetEvent('qbx_identity:server:endSpawnSelection', function()
    local src = source
    local state = Player(src)?.state

    if state then
        state:set('inProperty', false, true)
    end
end)

lib.addCommand('setslots', {
    help = 'Set how many character slots a player has',
    restricted = config.slotsPermission,
    params = {
        { name = 'id', type = 'playerId', help = 'Player ID' },
        { name = 'slots', type = 'number', help = 'Slot amount (1 - ' .. config.maxNumberOfCharacters .. ')' }
    }
}, function(source, args)
    local target = args.id
    local license = GetPlayerIdentifierByType(target, 'license2') or GetPlayerIdentifierByType(target, 'license')

    if not license then
        exports.qbx_core:Notify(source, 'Player license not found', 'error')
        return
    end

    local amount = clamp(math.floor(args.slots))

    MySQL.query.await(('INSERT INTO `%s` (license, slots) VALUES (?, ?) ON DUPLICATE KEY UPDATE slots = ?'):format(config.slotsTable), {
        license, amount, amount
    })

    slotCache[target] = amount

    exports.qbx_core:Notify(source, ('%s now has %s character slots'):format(GetPlayerName(target), amount), 'success')
    exports.qbx_core:Notify(target, ('Your character slots have been set to %s'):format(amount), 'inform')
    lib.print.info(('%s [%s] set the slots for %s to %s'):format(GetPlayerName(source), source, license, amount))
end)
