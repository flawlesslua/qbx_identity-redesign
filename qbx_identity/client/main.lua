local config = require 'config.client'

if config.useExternalCharacters then return end

local defaultModels = {
    [0] = `mp_m_freemode_01`,
    [1] = `mp_f_freemode_01`
}

local cam
local nations = {}
local slots = {}
local selected = 1
local uiOpen = false
local uiReady = false
local sceneActive = false
local inputLocked = false
local animActive = false
local animData
local previewToken = 0
local formGender = 0
local loggedIn = false
local spawnMode = false
local allowDelete = false
local spawnCam
local spawnPoint
local spawnToken = 0
local loadedAnnounced = false
local sessionEnded = false

local function setFocus(state)
    uiOpen = state
    SetNuiFocus(state, state)
end

local function closeUI()
    SendNUIMessage({ action = 'closeui' })

    if uiOpen then
        setFocus(false)
    end
end

local function placePed()
    local ped = PlayerPedId()
    local spawn = config.spawn

    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
    SetEntityHeading(ped, spawn.w)
end

local function showPed(state)
    local ped = PlayerPedId()

    SetPedAoBlobRendering(ped, state)
    SetEntityVisible(ped, state, false)

    if state then
        ResetEntityAlpha(ped)
    else
        SetEntityAlpha(ped, 0, false)
    end
end

local function applyCamera(cfg)
    if not cam then return end

    local ped = PlayerPedId()
    local offset = GetOffsetFromEntityInWorldCoords(ped, cfg.side, cfg.forward, cfg.height)
    local target = GetOffsetFromEntityInWorldCoords(ped, cfg.pointSide, 0.0, cfg.pointZ)

    SetCamCoord(cam, offset.x, offset.y, offset.z - cfg.drop)
    SetCamFov(cam, cfg.fov)
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

local function createCamera(cfg)
    local ped = PlayerPedId()
    local offset = GetOffsetFromEntityInWorldCoords(ped, cfg.side, cfg.forward, cfg.height)
    local target = GetOffsetFromEntityInWorldCoords(ped, cfg.pointSide, 0.0, cfg.pointZ)

    cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', offset.x, offset.y, offset.z - cfg.drop, 0.0, 0.0, 0.0, cfg.fov, false, 0)

    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

local function destroyCamera()
    if not cam then return end

    SetCamActive(cam, false)
    DestroyCam(cam, true)
    RenderScriptCams(false, false, 0, true, true)
    cam = nil
end

local function applyAnimation()
    local anim = animData
    if not anim then return end

    if not HasAnimDictLoaded(anim.dict) then
        RequestAnimDict(anim.dict)

        local timeout = GetGameTimer() + config.animTimeout
        while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < timeout do
            RequestAnimDict(anim.dict)
            Wait(10)
        end

        if not HasAnimDictLoaded(anim.dict) then
            lib.print.warn(('failed to load anim dict %s'):format(anim.dict))
            return
        end
    end

    if not animActive then return end

    local ped = PlayerPedId()

    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    placePed()
    TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    Wait(100)

    if not animActive then
        FreezeEntityPosition(ped, false)
        ClearPedTasksImmediately(ped)
        return
    end

    FreezeEntityPosition(ped, true)
end

local function stopAnimation()
    animActive = false
    animData = nil
end

local function startAnimation(gender)
    local anim = config.selectAnimation[gender] or config.selectAnimation[0]

    if not anim or not anim.dict or not anim.name then return end

    animData = anim

    if animActive then return end

    animActive = true

    CreateThread(function()
        while animActive do
            local current = animData

            if current and not IsEntityPlayingAnim(PlayerPedId(), current.dict, current.name, 3) then
                applyAnimation()
            end

            Wait(300)
        end
    end)
end

local function lockScene()
    if sceneActive then return end

    sceneActive = true

    CreateThread(function()
        local keys = config.allowedControls

        while sceneActive do
            SetPlayerInvincible(cache.playerId, true)
            ThefeedHideThisFrame()
            HideHudAndRadarThisFrame()

            if inputLocked then
                DisableAllControlActions(0)

                for i = 1, #keys do
                    EnableControlAction(0, keys[i], true)
                end
            end

            SetWeatherTypePersist(config.weather)
            SetWeatherTypeNowPersist(config.weather)
            SetWeatherTypeNow(config.weather)
            NetworkOverrideClockTime(config.time[1], config.time[2], config.time[3])

            Wait(0)
        end

        local ped = PlayerPedId()

        SetPlayerInvincible(cache.playerId, false)
        FreezeEntityPosition(ped, false)
        ResetEntityAlpha(ped)
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        NetworkClearClockTimeOverride()
        DisplayRadar(true)
    end)
end

local function unlockScene()
    sceneActive = false
    inputLocked = false
end

local function resolveModel(model, gender)
    local fallback = defaultModels[gender] or defaultModels[0]

    if not model then return fallback end

    if type(model) == 'string' then
        model = joaat(model)
    end

    if type(model) ~= 'number' or not IsModelInCdimage(model) or not IsModelValid(model) then
        lib.print.warn(('ped model %s is not valid, falling back to the default model'):format(model))
        return fallback
    end

    return model
end

local function applyPedModel(model, gender)
    model = resolveModel(model, gender)

    local ok = pcall(lib.requestModel, model, config.loadingModelsTimeout)

    if not ok or not HasModelLoaded(model) then
        lib.print.error(('ped model %s failed to load, falling back to the default model'):format(model))

        model = defaultModels[gender] or defaultModels[0]
        pcall(lib.requestModel, model, config.loadingModelsTimeout)
    end

    SetPlayerModel(cache.playerId, model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()

    SetPedDefaultComponentVariation(ped)

    return ped
end

local function applyPedAppearance(ped, clothing)
    if not clothing then return false end

    local resource = config.appearance.resource

    if GetResourceState(resource) ~= 'started' then
        lib.print.warn(('%s is not running, appearance preview skipped'):format(resource))
        return false
    end

    if type(clothing) == 'string' then
        local decoded, result = pcall(json.decode, clothing)

        if not decoded or type(result) ~= 'table' then
            lib.print.error('character skin is not valid JSON, appearance preview skipped')
            return false
        end

        clothing = result
    end

    if type(clothing) ~= 'table' then return false end

    local ok, err = pcall(function()
        exports[resource]:setPedAppearance(ped, clothing)
    end)

    if not ok then
        lib.print.error(('%s:setPedAppearance failed: %s'):format(resource, err))
        return false
    end

    return true
end

local function applyDefaultPed(gender)
    applyPedModel(nil, gender)
end

local function previewSlot(id)
    previewToken += 1

    local token = previewToken
    local slot = slots[id]

    if not slot or not slot.filled then
        stopAnimation()
        showPed(false)
        return
    end

    local clothing, model = lib.callback.await('qbx_core:server:getPreviewPedData', false, slot.citizenid)

    if token ~= previewToken then return end

    local ped = applyPedModel(model, slot.gender)

    applyPedAppearance(ped, clothing)

    if token ~= previewToken then return end

    placePed()
    startAnimation(slot.gender)
    showPed(true)
end

local function buildSlots(characters, amount)
    local list = {}

    for i = 1, amount do
        list[i] = { id = i, filled = false }
    end

    for i = 1, #characters do
        local character = characters[i]
        local id = character.charinfo.cid or i

        if id >= 1 and id <= amount then
            list[id] = {
                id = id,
                filled = true,
                citizenid = character.citizenid,
                firstname = character.charinfo.firstname,
                lastname = character.charinfo.lastname,
                gender = character.charinfo.gender or 0,
                height = character.charinfo.height,
                birthdate = character.charinfo.birthdate,
                nationality = character.charinfo.nationality,
                cash = character.money.cash,
                bank = character.money.bank,
                job = character.job and character.job.label,
                jobGrade = character.job and character.job.grade and character.job.grade.name,
                gang = character.gang and character.gang.label,
                gangGrade = character.gang and character.gang.grade and character.gang.grade.name,
                lastLoggedOut = character.lastLoggedOut
            }
        end
    end

    return list
end

local function hasAnyCharacter()
    for i = 1, #slots do
        if slots[i].filled then return true end
    end

    return false
end

local function firstFilled()
    for i = 1, #slots do
        if slots[i].filled then return i end
    end

    return 1
end

local function sendOpen(startCreate)
    SendNUIMessage({
        action = 'openui',
        startCreate = startCreate == true,
        slots = slots,
        selected = selected,
        canDelete = config.enableDeleteButton and allowDelete,
        nations = nations,
        sound = config.sound,
        config = {
            minHeight = config.minHeight,
            maxHeight = config.maxHeight,
            minYear = config.minYear,
            maxYear = config.maxYear,
            maxWords = config.maxWords,
            maxText = config.maxText
        }
    })
end

local function refreshSlots()
    local characters, amount, canDelete = lib.callback.await('qbx_core:server:getCharacters')

    allowDelete = canDelete == true
    slots = buildSlots(characters, amount)
    selected = firstFilled()
end

local function streetNameAt(coords)
    local hash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

    if not hash or hash == 0 then return end

    local name = GetStreetNameFromHashKey(hash)

    if name and name ~= '' then return name end
end

local function findSpawnLocation(id)
    local list = config.spawnSelector.locations

    for i = 1, #list do
        if list[i].id == id then return list[i] end
    end
end

local function spawnCameraFor(location)
    local defaults = config.spawnSelector.camera

    return {
        radius = location.radius or defaults.radius,
        height = location.height or defaults.height,
        lookHeight = location.lookHeight or defaults.lookHeight,
        fov = location.fov or defaults.fov
    }
end

local function destroySpawnCamera()
    if not spawnCam then return end

    SetCamActive(spawnCam, false)
    DestroyCam(spawnCam, true)
    RenderScriptCams(false, false, 0, true, true)
    spawnCam = nil
end

local function orbitSpawnCamera()
    CreateThread(function()
        local angle = 0.0

        while spawnMode do
            local point = spawnPoint

            if point and spawnCam then
                angle = angle + config.spawnSelector.orbitSpeed * GetFrameTime()

                local cam = point.cam
                local x = point.coords.x + math.sin(angle) * cam.radius
                local y = point.coords.y + math.cos(angle) * cam.radius

                SetCamCoord(spawnCam, x, y, point.coords.z + cam.height)
                PointCamAtCoord(spawnCam, point.coords.x, point.coords.y, point.coords.z + cam.lookHeight)
            end

            Wait(0)
        end

        destroySpawnCamera()
    end)
end

local function focusSpawnPoint(coords, cam)
    spawnToken = spawnToken + 1

    local token = spawnToken
    local selector = config.spawnSelector

    DoScreenFadeOut(selector.switchFade)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    if token ~= spawnToken then return end

    spawnPoint = { coords = coords, cam = cam }

    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    NewLoadSceneStartSphere(coords.x, coords.y, coords.z, selector.loadRadius or 400.0, 0)

    local deadline = GetGameTimer() + selector.switchTimeout

    while not IsNewLoadSceneLoaded() and GetGameTimer() < deadline do
        Wait(10)
    end

    NewLoadSceneStop()

    if token ~= spawnToken then return end

    if not spawnCam then
        spawnCam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z + cam.height, 0.0, 0.0, 0.0, cam.fov, false, 0)
        SetCamActive(spawnCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end

    SetCamFov(spawnCam, cam.fov)
    DoScreenFadeIn(selector.switchFade)
end

local function openSpawnSelector()
    local selector = config.spawnSelector
    local playerData = exports.qbx_core:GetPlayerData()
    local last = selector.showLastLocation and playerData and playerData.position or nil
    local payload = {}

    for i = 1, #selector.locations do
        local location = selector.locations[i]

        payload[i] = {
            id = location.id,
            label = location.label,
            name = location.name,
            desc = location.desc,
            tags = location.tags
        }
    end

    spawnMode = true
    spawnToken = 0

    TriggerServerEvent('qbx_identity:server:beginSpawnSelection')

    stopAnimation()
    destroyCamera()
    showPed(false)
    orbitSpawnCamera()

    SendNUIMessage({
        action = 'openspawn',
        sound = config.sound,
        locations = payload,
        last = last and {
            id = 'last',
            label = selector.lastLabel,
            name = streetNameAt(last) or selector.lastName,
            desc = selector.lastDesc,
            tags = selector.lastTags
        } or nil
    })

    setFocus(true)

    if last then
        focusSpawnPoint(last, selector.camera)
    elseif selector.locations[1] then
        focusSpawnPoint(selector.locations[1].coords, spawnCameraFor(selector.locations[1]))
    end
end

local function closeSpawnSelector()
    spawnMode = false
    spawnPoint = nil
    spawnToken = spawnToken + 1

    ClearFocus()
    destroySpawnCamera()
    TriggerServerEvent('qbx_identity:server:endSpawnSelection')
end

local function leaveScene()
    stopAnimation()
    closeUI()
    unlockScene()
    destroyCamera()
end

local function announceLoaded()
    if loadedAnnounced then return end

    loadedAnnounced = true

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
end

local function enterSession()
    sessionEnded = false
    TriggerServerEvent('qbx_identity:server:enterSelection')
    Wait(config.bucketSettleDelay)
end

local function endSession()
    if sessionEnded then return end

    sessionEnded = true

    leaveScene()
    TriggerServerEvent('qbx_identity:server:leaveSelection')
end

local function spawnAt(coords)
    DoScreenFadeOut(500)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    leaveScene()

    local ped = PlayerPedId()

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, false)

    if GetResourceState('spawnmanager') == 'started' then
        local ok, err = pcall(function() exports.spawnmanager:spawnPlayer({
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = coords.w
        }) end)

        if not ok then
            lib.print.error(('spawnmanager failed, falling back to a direct teleport: %s'):format(err))
        end
    else
        lib.print.warn('spawnmanager is not running, using a direct teleport')
    end

    local settle = GetGameTimer() + config.collisionTimeout

    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < settle do
        Wait(10)
    end

    lib.print.info(('spawned at %.2f %.2f %.2f'):format(coords.x, coords.y, coords.z))

    announceLoaded()
    endSession()
    DoScreenFadeIn(500)

    local faded = GetGameTimer() + config.collisionTimeout

    while not IsScreenFadedIn() and GetGameTimer() < faded do
        Wait(0)
    end
end

local function spawnNewCharacter()
    spawnAt(config.newCharacterPoint or exports.qbx_core:GetDefaultSpawn())
end

local function spawnLastLocation()
    spawnAt(exports.qbx_core:GetPlayerData().position)
end

local function routeNewCharacter(newData)
    local destination = config.newCharacterSpawn

    if destination == 'apartment' and GetResourceState('qbx_apartments'):find('start') then
        endSession()
        TriggerEvent('apartments:client:setupSpawnUI', newData)
        return
    end

    if destination == 'spawnselector' and GetResourceState('qbx_spawn'):find('start') then
        endSession()
        TriggerEvent('qb-spawn:client:setupSpawns', newData)
        TriggerEvent('qb-spawn:client:openUI', true)
        return
    end

    spawnNewCharacter()
end

local function capturePed()
    local ped = PlayerPedId()
    local snapshot = { model = GetEntityModel(ped) }

    pcall(function() snapshot.appearance = exports[config.appearance.resource]:getPedAppearance(ped) end)

    return snapshot
end

local function restorePed(snapshot)
    if not snapshot then return end

    local ped = PlayerPedId()

    if snapshot.model and GetEntityModel(ped) ~= snapshot.model then
        lib.print.warn('ped model changed after the cinematic, restoring it')
        lib.requestModel(snapshot.model, config.loadingModelsTimeout)
        SetPlayerModel(cache.playerId, snapshot.model)
        SetModelAsNoLongerNeeded(snapshot.model)
        ped = PlayerPedId()
    end

    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped, true)

    for i = 0, 8 do
        ClearPedProp(ped, i)
    end

    if snapshot.appearance then
        pcall(function() exports[config.appearance.resource]:setPedAppearance(ped, snapshot.appearance) end)
    end
end

local function waitForPlayerData()
    local timeout = GetGameTimer() + config.appearance.dataTimeout

    while GetGameTimer() < timeout do
        local data = exports.qbx_core:GetPlayerData()

        if data and data.citizenid and data.charinfo and data.job and data.gang then
            lib.print.info(('PlayerData ready: cid=%s job=%s gang=%s gender=%s'):format(
                data.citizenid,
                data.job.name,
                data.gang.name,
                data.charinfo.gender
            ))
            return true
        end

        Wait(50)
    end

    lib.print.error('incomplete PlayerData on the client, citizenid/charinfo/job/gang are not all present')
    return false
end

local function openAppearance()
    local ok, err = pcall(TriggerEvent, config.appearance.event)

    if not ok then
        lib.print.error(('event %s threw an error: %s'):format(config.appearance.event, err))
    end
end

local function runAppearance()
    local appearance = config.appearance

    if not appearance.enabled then return end
    if GetResourceState(appearance.resource) ~= 'started' then
        lib.print.warn(('%s is not running, appearance editor skipped'):format(appearance.resource))
        return
    end

    openAppearance()

    local opened = GetGameTimer() + appearance.openTimeout
    while not IsNuiFocused() and GetGameTimer() < opened do
        Wait(50)
    end

    if not IsNuiFocused() then
        lib.print.error(('appearance editor never opened, check the %s console for the error'):format(appearance.resource))
        return
    end

    local finished = GetGameTimer() + appearance.finishTimeout
    while IsNuiFocused() and GetGameTimer() < finished do
        Wait(250)
    end
end

local function finishNewCharacter(newData)
    local spawn = config.appearance.spawn or config.spawn

    stopAnimation()
    closeUI()
    destroyCamera()
    unlockScene()

    waitForPlayerData()
    spawnAt(spawn)
    Wait(config.appearance.initDelay)

    runAppearance()

    DoScreenFadeOut(500)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    if config.intro.enabled then
        local cid = newData and newData.charinfo and newData.charinfo.cid or 1
        local canSkip = not config.intro.onlyFirstCharacter and cid > 1
        local snapshot = capturePed()

        enterSession()
        RunIntroCutscene(canSkip)

        DoScreenFadeOut(300)

        while not IsScreenFadedOut() do
            Wait(0)
        end

        restorePed(snapshot)
    end

    routeNewCharacter(newData)
end

local function startSelection()
    loggedIn = false
    loadedAnnounced = false
    sessionEnded = false

    refreshSlots()

    DoScreenFadeOut(0)
    placePed()
    inputLocked = true
    lockScene()

    if cam then
        applyCamera(config.selectCamera)
    else
        createCamera(config.selectCamera)
    end

    NetworkStartSoloTutorialSession()

    local session = GetGameTimer() + config.sessionTimeout
    while not NetworkIsInTutorialSession() and GetGameTimer() < session do
        Wait(0)
    end

    local ready = GetGameTimer() + config.uiReadyTimeout
    while not uiReady and GetGameTimer() < ready do
        Wait(10)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    local fresh = config.skipSelectorWhenEmpty and not hasAnyCharacter()

    if fresh then
        formGender = 0
        stopAnimation()
        applyDefaultPed(formGender)
        placePed()
        showPed(true)
        applyCamera(config.createCamera)
    else
        previewSlot(selected)
    end

    sendOpen(fresh)
    setFocus(true)
    DoScreenFadeIn(750)
end

RegisterNUICallback('uiReady', function(_, cb)
    uiReady = true
    cb(1)
end)

RegisterNUICallback('selectSlot', function(data, cb)
    cb(1)

    local id = tonumber(data.slot)
    if not id then return end

    selected = id
    previewSlot(id)
end)

RegisterNUICallback('openCreate', function(data, cb)
    cb(1)

    formGender = tonumber(data.gender) or 0
    stopAnimation()

    if GetEntityModel(PlayerPedId()) ~= (defaultModels[formGender] or defaultModels[0]) then
        applyDefaultPed(formGender)
    end

    placePed()
    showPed(true)
    applyCamera(config.createCamera)
end)

RegisterNUICallback('previewGender', function(data, cb)
    cb(1)

    local gender = tonumber(data.gender)
    if not gender or gender == formGender then return end

    formGender = gender

    applyDefaultPed(gender)
    placePed()
    showPed(true)
    applyCamera(config.createCamera)
end)

RegisterNUICallback('backToSelect', function(_, cb)
    cb(1)

    applyCamera(config.selectCamera)
    previewSlot(selected)
end)

RegisterNUICallback('playCharacter', function(data, cb)
    cb(1)

    local id = tonumber(data.slot)
    local slot = id and slots[id]

    if not slot or not slot.filled then return end

    DoScreenFadeOut(250)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    closeUI()
    stopAnimation()

    local success = lib.callback.await('qbx_core:server:loadCharacter', false, slot.citizenid)

    if not success then
        sendOpen()
        setFocus(true)
        DoScreenFadeIn(250)
        return
    end

    if config.spawnSelector.enabled and #config.spawnSelector.locations > 0 then
        openSpawnSelector()
        return
    end

    if GetResourceState('qbx_apartments'):find('start') then
        leaveScene()
        TriggerEvent('apartments:client:setupSpawnUI', slot.citizenid)
    elseif GetResourceState('qbx_spawn'):find('start') then
        leaveScene()
        TriggerEvent('qb-spawn:client:setupSpawns', slot.citizenid)
        TriggerEvent('qb-spawn:client:openUI', true)
    else
        spawnLastLocation()
    end
end)

RegisterNUICallback('createCharacter', function(data, cb)
    cb(1)

    if not tonumber(data.slot) then return end

    local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
        firstname = data.firstname,
        lastname = data.lastname,
        height = data.height,
        nationality = data.nationality,
        gender = data.gender,
        birthdate = data.birthdate
    })

    if not newData then
        SendNUIMessage({ action = 'createResult', ok = false })
        return
    end

    DoScreenFadeOut(250)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    finishNewCharacter(newData)
end)

RegisterNUICallback('previewSpawn', function(data, cb)
    cb(1)

    if not spawnMode then return end

    if data.id == 'last' then
        local playerData = exports.qbx_core:GetPlayerData()

        if playerData and playerData.position then
            focusSpawnPoint(playerData.position, config.spawnSelector.camera)
        end

        return
    end

    local location = findSpawnLocation(data.id)

    if not location then return end

    focusSpawnPoint(location.coords, spawnCameraFor(location))
end)

RegisterNUICallback('confirmSpawn', function(data, cb)
    cb(1)

    if not spawnMode then return end

    local coords

    if data.id == 'last' then
        local playerData = exports.qbx_core:GetPlayerData()
        coords = playerData and playerData.position
    else
        local location = findSpawnLocation(data.id)
        coords = location and location.coords
    end

    if not coords then
        coords = exports.qbx_core:GetDefaultSpawn()
    end

    closeUI()
    closeSpawnSelector()
    spawnAt(coords)
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    cb(1)

    local id = tonumber(data.slot)
    local slot = id and slots[id]

    if not config.enableDeleteButton or not allowDelete or not slot or not slot.filled then return end

    local success = lib.callback.await('qbx_core:server:deleteCharacter', false, slot.citizenid)

    if success then
        refreshSlots()
    end

    local fresh = config.skipSelectorWhenEmpty and not hasAnyCharacter()

    if fresh then
        formGender = 0
        stopAnimation()
        applyDefaultPed(formGender)
        placePed()
        showPed(true)
        applyCamera(config.createCamera)
    else
        applyCamera(config.selectCamera)
        previewSlot(selected)
    end

    sendOpen(fresh)
end)

RegisterNetEvent('qbx_core:client:spawnNoApartments', function()
    local defaultSpawn = exports.qbx_core:GetDefaultSpawn()

    DoScreenFadeOut(500)
    Wait(2000)

    leaveScene()

    local ped = PlayerPedId()

    SetEntityCoords(ped, defaultSpawn.x, defaultSpawn.y, defaultSpawn.z, false, false, false, false)
    SetEntityHeading(ped, defaultSpawn.w)
    Wait(500)
    SetEntityVisible(ped, true, false)
    Wait(500)
    DoScreenFadeIn(250)

    announceLoaded()
    endSession()
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if loggedIn then return end

    loggedIn = true

    endSession()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end

    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
        Wait(250)
        ped = PlayerPedId()
    end

    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
        ped = PlayerPedId()
    end

    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))

    TriggerServerEvent('qbx_identity:server:enterSelection')
    Wait(config.bucketSettleDelay)
    startSelection()
end)

CreateThread(function()
    nations = lib.load('data.nationalities')

    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    local playerData = exports.qbx_core:GetPlayerData()

    if playerData and playerData.citizenid then
        loggedIn = true
        lib.print.info('character already active, selection skipped')
        return
    end

    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)

    TriggerServerEvent('qbx_identity:server:enterSelection')
    Wait(config.bucketSettleDelay)

    startSelection()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    spawnMode = false
    ClearFocus()
    destroySpawnCamera()
    stopAnimation()
    unlockScene()
    destroyCamera()
    SetNuiFocus(false, false)
end)
