--[[
    Shop locations.

    id         : unique id, stored in the database. Never rename it once the shop has data.
    zone       : box covering the whole shop interior (center, size, rotation in degrees).
                 Products and furniture only spawn while you are inside it, and walking out of
                 it with unpaid products triggers Config.theft.
    hideModels : map props hidden while you are inside the shop. Use it to clear the baked-in
                 shelves of a vanilla interior. Leave it empty for an empty custom MLO.
    blip       : optional map blip.

    The example below uses the vanilla 24/7 on Innocence Blvd so you can test before the
    custom MLO is ready. Furniture is placed in game with `/kios place <type>`.
]]

Config.Shops = {
    {
        id = 'innocence_247',
        label = '24/7 Innocence Blvd',
        zone = { center = vec3(28.6, -1344.6, 29.5), size = vec3(14.0, 14.0, 6.0), rotation = 0.0 },
        blip = { sprite = 52, color = 2, scale = 0.7 },
        hideModels = {
            -- 'v_ret_247shelves01',
        },
    },

    -- {
    --     id = 'kios_mlo_example',
    --     label = 'Kios (custom MLO)',
    --     zone = { center = vec3(0.0, 0.0, 0.0), size = vec3(18.0, 14.0, 6.0), rotation = 0.0 },
    --     blip = { sprite = 52, color = 2, scale = 0.7 },
    --     hideModels = {},
    -- },
}
