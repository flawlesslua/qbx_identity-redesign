local config = require 'config.server'

if not config.devCommands then return end

lib.addCommand('relog', {
    help = 'Return to character selection without reconnecting',
    restricted = config.devCommandsPermission,
}, function(source)
    if not exports.qbx_core:GetPlayer(source) then
        exports.qbx_core:Notify(source, 'You have not selected a character yet', 'error')
        return
    end

    lib.print.info(('%s [%s] used /relog'):format(GetPlayerName(source), source))
    exports.qbx_core:Logout(source)
end)
