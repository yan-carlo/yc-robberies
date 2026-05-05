fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'yc-dev'
description 'yc-robberies | Sistema de robos a tiendas/licorerias con vitrinas (DB-only state)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'origen_police',
    'qb-minigames',
    'qb-core',
    'oxmysql'
}
