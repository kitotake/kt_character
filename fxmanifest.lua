fx_version 'cerulean'
game 'gta5'

name 'kt_character'
author 'kitotake'
description 'Character Creator + Appearance (React TSX UI)'
version '1.0.0'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    -- Core (ordre important)
    'server/config.lua',
    'server/utils.lua',
    'server/identifiers.lua',
    'server/validator.lua',

    -- Features
    'server/character_create.lua',
    'server/character_load.lua',
    'server/character_skin.lua',
    'server/character_update.lua',
    'server/outfits.lua',
    'server/events.lua',

    -- Main (toujours en dernier)
    'server/main.lua'
}

client_exports {
    "ApplyFullAppearance",
    "ApplyOutfit",
    "ApplyPreview",
}