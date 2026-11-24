fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'kios'
description 'Physical convenience stores: real shelves, carried products, self-checkout and staffed registers'
version '0.1.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'config/shared.lua',
    'config/products.lua',
    'config/furniture.lua',
    'config/shops.lua',
}

client_scripts {
    'client/nui.lua',
    'client/props.lua',
    'client/state.lua',
    'client/carry.lua',
    'client/checkout.lua',
    'client/target.lua',
    'client/admin.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/init.lua',
    'bridge/server/qbx.lua',
    'bridge/server/qb.lua',
    'bridge/server/esx.lua',
    'bridge/server/ox.lua',
    'bridge/server/nd.lua',
    'server/db.lua',
    'server/state.lua',
    'server/carry.lua',
    'server/checkout.lua',
    'server/admin.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/assets/*',
    'web/dot.png',
}

dependencies {
    '/onesync',
    'ox_lib',
    'oxmysql',
    'ox_inventory',
}
