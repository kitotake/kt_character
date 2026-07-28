fx_version 'cerulean'
game 'gta5'

name        'kt_character'
author      'kitotake'
description 'KT Character — Core module (ped, preview, apparence, BDD)'
version     '3.0.0'

dependencies {
    'oxmysql',
    'union',
}

-- ── SHARED ────────────────────────────────────────────────────────────────
shared_scripts {
    'shared/config.lua',
    'shared/events.lua',
}

-- ── CLIENT ────────────────────────────────────────────────────────────────
-- Ordre important : core avant api avant main
client_scripts {
    'client/core/state.lua',
    'client/core/ped.lua',
    'client/core/camera.lua',
    'client/core/preview.lua',
    'client/core/events.lua',
    'client/api/exports.lua',
    'client/main.lua',
}

-- ── SERVER ────────────────────────────────────────────────────────────────
-- Ordre important : utils → core → api → main
server_scripts {
    'server/utils/utils.lua',
    'server/utils/identifiers.lua',
    'server/utils/validator.lua',
    'server/core/character.lua',
    'server/core/appearance.lua',
    'server/core/outfits.lua',
    'server/api/exports.lua',
    'server/main.lua',
}

-- ── EXPORTS CLIENT (déclarés pour les autres ressources) ──────────────────
client_exports {
    -- Preview
    'Preview_Start',
    'Preview_Stop',
    'Preview_Refresh',
    'Preview_SetCamera',
    'Preview_CameraAction',
    'Preview_Rotate',
    'Preview_SetFaceZoom',
    'Preview_IsActive',
    'Preview_GetPed',
    'Preview_PlayAnim',
    'Preview_ResetAnim',
    -- Preview → appliquer sur ped clone
    'Preview_ApplyAppearance',
    'Preview_ApplyClothing',
    'Preview_ApplyHair',
    'Preview_ApplyTattoos',
    'Preview_ApplyPartial',
    -- Apparence → appliquer sur joueur
    'Appearance_Apply',
    'Appearance_ApplyClothing',
    'Appearance_ApplyHair',
    'Appearance_ApplyTattoos',
    'Appearance_ApplyOutfit',
    -- Données
    'Character_GetUniqueId',
    'Character_GetCurrentAppearance',
    'Character_GetIdentifier',
}

-- ── EXPORTS SERVER (déclarés pour les autres ressources) ──────────────────
server_exports {
    'Character_GetUniqueId',
    'Character_GetData',
    'Character_IsActive',
    'Character_SaveAppearance',
    'Character_SaveClothing',
    'Character_SaveTattoos',
    'Character_SaveHair',
    'On',
    'Emit',
}
