local config = require 'config.client'

local passengerSlots = {
    [0] = 'MP_Plane_Passenger_1',
    [1] = 'MP_Plane_Passenger_2',
    [2] = 'MP_Plane_Passenger_3',
    [3] = 'MP_Plane_Passenger_4',
    [4] = 'MP_Plane_Passenger_5',
    [5] = 'MP_Plane_Passenger_6',
    [6] = 'MP_Plane_Passenger_7'
}

local femaleSlots = {
    [1] = true,
    [2] = true,
    [4] = true,
    [6] = true
}

local function clearProps(ped)
    for i = 0, 8 do
        ClearPedProp(ped, i)
    end
end

local function createPassengers()
    local intro = config.intro
    local spawn = intro.passengerSpawn
    local peds = {}

    for slot = 0, 6 do
        local model = femaleSlots[slot] and `mp_f_freemode_01` or `mp_m_freemode_01`

        lib.requestModel(model, config.loadingModelsTimeout)

        local ped = CreatePed(26, model, spawn.x, spawn.y, spawn.z, 0.0, false, false)

        if DoesEntityExist(ped) then
            SetPedRandomComponentVariation(ped, 0)
            clearProps(ped)
            FinalizeHeadBlend(ped)
            NetworkSetEntityInvisibleToNetwork(ped, true)
            RegisterEntityForCutscene(ped, passengerSlots[slot], 0, 0, 64)
            peds[#peds + 1] = ped
        end

        SetModelAsNoLongerNeeded(model)
    end

    return peds
end

local function registerPlayer(ped, male)
    local own = male and 'MP_Male_Character' or 'MP_Female_Character'
    local other = male and 'MP_Female_Character' or 'MP_Male_Character'

    RegisterEntityForCutscene(0, own, 3, GetEntityModel(ped), 0)
    RegisterEntityForCutscene(ped, own, 0, 0, 0)
    SetCutsceneEntityStreamingFlags(own, 0, 1)

    local hidden = RegisterEntityForCutscene(0, other, 3, 0, 64)

    if hidden and hidden ~= 0 and DoesEntityExist(hidden) then
        NetworkSetEntityInvisibleToNetwork(hidden, true)
    end
end

local function streamStage()
    local intro = config.intro
    local stage = intro.stagePoint
    local ped = PlayerPedId()

    SetEntityCoords(ped, stage.x, stage.y, stage.z, false, false, false, false)
    SetEntityHeading(ped, intro.stageHeading)
    FreezeEntityPosition(ped, true)
    SetFocusPosAndVel(stage.x, stage.y, stage.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(stage.x, stage.y, stage.z)
    NewLoadSceneStartSphere(stage.x, stage.y, stage.z, intro.loadSceneRadius, 0)

    local scene = GetGameTimer() + intro.sceneTimeout

    while not IsNewLoadSceneLoaded() and GetGameTimer() < scene do
        Wait(10)
    end

    NewLoadSceneStop()

    local collision = GetGameTimer() + intro.sceneTimeout

    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < collision do
        Wait(10)
    end

    FreezeEntityPosition(PlayerPedId(), false)
    lib.print.info(('cinematic stage ready at %.2f %.2f %.2f'):format(stage.x, stage.y, stage.z))
end

local function followCamera()
    CreateThread(function()
        local intro = config.intro
        local last = GetFinalRenderedCamCoord()

        while IsCutsceneActive() do
            local now = GetFinalRenderedCamCoord()
            local delta = GetFrameTime()
            local velocity = delta > 0.0 and ((now - last) / delta) or vec3(0.0, 0.0, 0.0)

            SetFocusPosAndVel(now.x, now.y, now.z, velocity.x, velocity.y, velocity.z)
            SetHdArea(now.x, now.y, now.z, intro.hdRadius)
            RequestCollisionAtCoord(now.x, now.y, now.z)

            last = now
            Wait(0)
        end

        ClearHdArea()
        ClearFocus()
    end)
end

local function drawHint(text)
    SetTextFont(4)
    SetTextScale(0.42, 0.42)
    SetTextColour(255, 255, 255, 170)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.925)
end

local function cleanup(peds)
    local intro = config.intro

    for i = 1, #peds do
        if DoesEntityExist(peds[i]) then
            DeleteEntity(peds[i])
        end
    end

    RemoveCutscene()
    ClearHdArea()
    ClearFocus()
    PrepareMusicEvent(intro.musicStop)
    TriggerMusicEvent(intro.musicStop)
end

function RunIntroCutscene(canSkip)
    local intro = config.intro

    if not intro.enabled then return false end

    local ped = PlayerPedId()
    local male = IsPedMale(ped)

    streamStage()

    PrepareMusicEvent(intro.musicStart)
    RequestCutsceneWithPlaybackList('MP_INTRO_CONCAT', male and intro.playbackMale or intro.playbackFemale, 8)

    local loaded = GetGameTimer() + intro.loadTimeout

    while not HasCutsceneLoaded() and GetGameTimer() < loaded do
        Wait(10)
    end

    if not HasCutsceneLoaded() then
        lib.print.error('MP_INTRO_CONCAT failed to load in time, cinematic skipped')
        RemoveCutscene()
        ClearFocus()
        return false
    end

    registerPlayer(ped, male)

    local peds = createPassengers()

    SetWeatherTypeNow(intro.weather)
    TriggerMusicEvent(intro.musicStart)
    StartCutscene(4)

    local started = GetGameTimer() + intro.startTimeout

    while not IsCutscenePlaying() and GetGameTimer() < started do
        Wait(0)
    end

    if not IsCutscenePlaying() then
        lib.print.error('MP_INTRO_CONCAT loaded but never started playing')
        cleanup(peds)
        return false
    end

    followCamera()
    Wait(intro.warmupDelay)
    DoScreenFadeIn(500)

    local deadline = GetGameTimer() + intro.maxDuration
    local skipped = false

    while IsCutscenePlaying() and GetGameTimer() < deadline do
        if canSkip then
            drawHint(intro.skipHint)

            if IsControlJustPressed(0, intro.skipControl) then
                skipped = true
                break
            end
        end

        Wait(0)
    end

    lib.print.info(('cinematic finished, skipped=%s'):format(skipped))

    DoScreenFadeOut(skipped and 200 or 800)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    if IsCutsceneActive() then
        StopCutsceneImmediately()
    end

    cleanup(peds)

    return true
end
