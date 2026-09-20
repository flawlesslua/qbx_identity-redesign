return {
    useExternalCharacters = false,
    enableDeleteButton = true,
    skipSelectorWhenEmpty = true,

    newCharacterSpawn = 'default',
    newCharacterPoint = vec4(-1037.63, -2737.8, 20.17, 325.72),

    sound = {
        enabled = true,
        volume = 0.35,
        throttle = 60,
        pool = 4,

        click = {
            enabled = true,
            volume = 0.5,
            rate = 0.85,
            throttle = 40,
            pool = 2
        }
    },

    spawnSelector = {
        enabled = true,
        showLastLocation = true,
        switchFade = 200,
        switchTimeout = 2500,
        loadRadius = 400.0,
        orbitSpeed = 0.12,

        lastLabel = 'Last Location',
        lastName = 'Last Location',
        lastDesc = 'Pick up from wherever you last left the city.',
        lastTags = { 'Saved position' },

        camera = {
            radius = 24.0,
            height = 13.0,
            lookHeight = 1.5,
            fov = 55.0
        },

        locations = {
            {
                id = 'lsia',
                label = 'International Airport',
                name = 'International Airport',
                desc = 'The main Los Santos terminal. Standard arrival point, close to taxis and vehicle rentals.',
                tags = { 'Airport', 'Taxis', 'Rentals' },
                coords = vec4(-1037.63, -2737.8, 20.17, 325.72)
            },
            {
                id = 'port',
                label = 'International Port',
                name = 'International Port',
                desc = 'The dockyards south of the city. Busy with containers, ship crews and heavy vehicles.',
                tags = { 'Docks', 'Industrial', 'South side' },
                coords = vec4(-716.82, -1294.66, 5.0, 50.37),
                radius = 30.0,
                height = 17.0
            },
            {
                id = 'sandy',
                label = 'Sandy Shores',
                name = 'Sandy Shores',
                desc = 'A desert town in Blaine County. Far from the crowds, next to the airstrip.',
                tags = { 'Desert', 'Rural', 'Airstrip' },
                coords = vec4(1542.09, 3784.19, 34.21, 205.13)
            },
            {
                id = 'paleto',
                label = 'Paleto',
                name = 'Paleto Bay',
                desc = 'The northernmost small town. Forest, ocean, and one main road running through it.',
                tags = { 'North', 'Forest', 'Remote' },
                coords = vec4(-145.11, 6437.58, 31.43, 316.41)
            }
        }
    },

    intro = {
        enabled = true,
        onlyFirstCharacter = false,
        skipControl = 22,
        skipHint = 'Press SPACE to skip',
        playbackMale = 31,
        playbackFemale = 103,
        weather = 'EXTRASUNNY',
        musicStart = 'FM_INTRO_START',
        musicStop = 'AC_STOP',
        stagePoint = vec3(-1212.79, -1673.52, 7.0),
        stageHeading = 0.0,
        passengerSpawn = vec3(-1117.78, -1557.62, 3.38),
        loadSceneRadius = 1000.0,
        hdRadius = 150.0,
        warmupDelay = 1500,
        loadTimeout = 20000,
        sceneTimeout = 10000,
        startTimeout = 5000,
        maxDuration = 45000
    },

    appearance = {
        enabled = true,
        resource = 'illenium-appearance',
        event = 'qb-clothes:client:CreateFirstCharacter',
        spawn = nil,
        dataTimeout = 10000,
        initDelay = 1500,
        openTimeout = 15000,
        finishTimeout = 900000
    },

    spawn = vec4(-578.37, 45.25, 91.24, 185.77),

    selectCamera = {
        forward = 3.2,
        side = 2.4,
        height = 1.5,
        drop = 0.45,
        pointSide = -0.5,
        pointZ = 0.0,
        fov = 30.0
    },

    createCamera = {
        forward = 2.2,
        side = 1.1,
        height = 0.7,
        drop = 0.0,
        pointSide = -0.15,
        pointZ = 0.55,
        fov = 38.0
    },

    selectAnimation = {
        [0] = { dict = 'timetable@ron@ig_5_p3', name = 'ig_5_p3_base' },
        [1] = { dict = 'timetable@reunited@ig_10', name = 'base_amanda' }
    },

    weather = 'EXTRASUNNY',
    time = { 12, 0, 0 },

    allowedControls = { 18, 27, 172, 173, 174, 175, 176, 177, 187, 188, 191, 201, 108, 109 },

    loadingModelsTimeout = 30000,
    animTimeout = 5000,
    sessionTimeout = 5000,
    uiReadyTimeout = 10000,
    bucketSettleDelay = 500,
    collisionTimeout = 5000,

    minHeight = 120,
    maxHeight = 220,
    minYear = 1900,
    maxYear = 2006,
    maxWords = 5,
    maxText = 50,
}
