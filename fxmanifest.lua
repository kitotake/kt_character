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
    'server/*.lua'
}