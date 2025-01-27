fx_version 'adamant'
game 'gta5'

author 'csoves0956'
description 'Egyedi Bérlő rendszer'
version '1.0.1'

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config.lua'
}

dependencies {
    'ox_target',
    'ox_lib',
    'es_extended' 
}

lua54 'yes'
