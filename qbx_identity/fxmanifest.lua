fx_version 'cerulean'
game 'gta5'

name 'qbx_identity'
description 'Character creation and selection for the Qbox Framework'
version '2.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/intro.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/buckets.lua',
    'server/main.lua',
    'server/commands.lua',
}

ui_page 'html/index.html'

files {
    'data/*.lua',
    'config/client.lua',
    'locales/*.json',
    'html/index.html',
    'html/css/main.css',
    'html/js/app.js',
    'html/fonts/*.woff2',
    'html/sounds/*.ogg',
    'html/locales/language.json',
}

dependencies {
    '/server:10731',
    '/onesync',
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
