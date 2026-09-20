return {
    defaultNumberOfCharacters = 1,
    maxNumberOfCharacters = 10,
    slotsTable = 'qbx_identity_slots',
    slotsPermission = 'group.admin',

    deletePermission = 'group.admin',

    maxTextLength = 50,
    maxBackstoryLength = 1000,
    maxWords = 5,

    minHeight = 120,
    maxHeight = 220,
    minYear = 1900,
    maxYear = 2006,

    profanityWords = {
        ['bad word'] = true
    },

    devCommands = true,
    devCommandsPermission = 'group.admin',

    bucketBase = 9000,
    bucketFallback = 900000,
    bucketPopulation = true,
    bucketDebug = false,
}
