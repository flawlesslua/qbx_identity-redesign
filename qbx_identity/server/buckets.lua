local config = require 'config.server'

local assigned = {}

local function assignBucket(source)
    local bucket = config.bucketBase + source

    if assigned[source] == bucket and GetPlayerRoutingBucket(source) == bucket then
        return bucket
    end

    SetPlayerRoutingBucket(source, bucket)
    SetRoutingBucketPopulationEnabled(bucket, config.bucketPopulation)
    SetRoutingBucketEntityLockdownMode(bucket, 'relaxed')

    assigned[source] = bucket

    if config.bucketDebug then
        lib.print.info(('player %s entered bucket %s'):format(source, bucket))
    end

    return bucket
end

local function releaseBucket(source)
    if not assigned[source] then return end

    SetPlayerRoutingBucket(source, 0)
    assigned[source] = nil

    if config.bucketDebug then
        lib.print.info(('player %s returned to bucket 0'):format(source))
    end
end

local function scheduleFallback(source)
    local bucket = assigned[source]
    if not bucket then return end

    SetTimeout(config.bucketFallback, function()
        if assigned[source] == bucket then
            lib.print.warn(('fallback: player %s is still in bucket %s, forcing them back'):format(source, bucket))
            releaseBucket(source)
        end
    end)
end

RegisterNetEvent('qbx_identity:server:enterSelection', function()
    assignBucket(source)
end)

RegisterNetEvent('qbx_identity:server:leaveSelection', function()
    releaseBucket(source)
end)

AddEventHandler('playerDropped', function()
    assigned[source] = nil
end)

AddEventHandler('qbx_identity:characterChosen', function(playerId)
    scheduleFallback(playerId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for source in pairs(assigned) do
        SetPlayerRoutingBucket(source, 0)
    end

    assigned = {}
end)

exports('GetSelectionBucket', function(source)
    return assigned[source]
end)
