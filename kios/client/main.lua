local txd = CreateRuntimeTxd('kios_ui')
CreateRuntimeTextureFromImage(txd, 'dot', 'web/dot.png')

local zones, blips = {}, {}

for _, cfg in ipairs(Config.Shops) do
    zones[#zones + 1] = lib.zones.box({
        coords = cfg.zone.center,
        size = cfg.zone.size,
        rotation = cfg.zone.rotation or 0.0,
        debug = Config.debug,
        onEnter = function()
            CreateThread(function() Shop.enter(cfg) end)
        end,
        onExit = function()
            if Shop.current and Shop.current.id == cfg.id then Shop.exit() end
        end,
    })

    if cfg.blip then
        local blip = AddBlipForCoord(cfg.zone.center.x, cfg.zone.center.y, cfg.zone.center.z)
        SetBlipSprite(blip, cfg.blip.sprite or 52)
        SetBlipColour(blip, cfg.blip.color or 2)
        SetBlipScale(blip, cfg.blip.scale or 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(cfg.label)
        EndTextCommandSetBlipName(blip)
        blips[#blips + 1] = blip
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Shop.exit()
    for _, blip in ipairs(blips) do RemoveBlip(blip) end
end)
