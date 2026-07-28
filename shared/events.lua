-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — SHARED EVENTS
-- Centralise tous les noms d'événements pour éviter les typos.
-- Inclure dans fxmanifest.lua en shared_script.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KT = KT or {}
KT.Events = {

    -- ── CLIENT → SERVER ─────────────────────────────────────────────────
    C2S_CREATE_CHARACTER    = "kt_character:createCharacter",
    C2S_SELECT_CHARACTER    = "kt_character:selectCharacter",
    C2S_SAVE_APPEARANCE     = "kt_character:saveAppearance",
    C2S_SAVE_CLOTHING       = "kt_character:saveClothing",
    C2S_SAVE_TATTOOS        = "kt_character:saveTattoos",
    C2S_SAVE_HAIR           = "kt_character:saveHair",
    C2S_SAVE_OUTFIT         = "kt_character:saveOutfit",
    C2S_LOAD_OUTFIT         = "kt_character:loadOutfit",
    C2S_DELETE_OUTFIT       = "kt_character:deleteOutfit",
    C2S_GET_OUTFITS         = "kt_character:getOutfits",
    C2S_REQUEST_IDENTIFIER  = "kt_character:requestIdentifier",
    C2S_REQUEST_SKIN_EDIT   = "kt_character:requestSkinEdit",
    C2S_UPDATE_APPEARANCE   = "kt_character:updateAppearance",

    -- ── SERVER → CLIENT ─────────────────────────────────────────────────
    S2C_SPAWN               = "kt_character:spawn",
    S2C_CREATED             = "kt_character:created",
    S2C_CLOSE_UI            = "kt_character:closeUI",
    S2C_ERROR               = "kt_character:error",
    S2C_SUCCESS             = "kt_character:success",
    S2C_SEND_IDENTIFIER     = "kt_character:sendIdentifier",
    S2C_SKIN_EDIT_DATA      = "kt_character:skinEditData",
    S2C_OUTFIT_SAVED        = "kt_character:outfitSaved",
    S2C_OUTFITS_LIST        = "kt_character:outfitsList",
    S2C_OUTFIT_DELETED      = "kt_character:outfitDeleted",
    S2C_APPLY_OUTFIT        = "kt_character:applyOutfit",

    -- ── INTERNES (EventBus server-side) ──────────────────────────────────
    -- Ces events sont triggerés via TriggerEvent (pas network)
    -- et permettent aux autres ressources de s'abonner.
    INTERNAL_CHAR_SELECTED      = "kt_character:internal:characterSelected",
    INTERNAL_CHAR_SPAWNED       = "kt_character:internal:characterSpawned",
    INTERNAL_CHAR_CREATED       = "kt_character:internal:characterCreated",
    INTERNAL_APPEARANCE_SAVED   = "kt_character:internal:appearanceSaved",
    INTERNAL_CLOTHING_SAVED     = "kt_character:internal:clothingSaved",
    INTERNAL_TATTOOS_SAVED      = "kt_character:internal:tattoosSaved",
    INTERNAL_OUTFIT_APPLIED     = "kt_character:internal:outfitApplied",

    -- ── PREVIEW (client-side, cross-resource) ────────────────────────────
    -- Utilisés par kt_creation, kt_clothing, kt_barber, etc.
    -- via exports kt_character côté Lua.
    PREVIEW_STARTED             = "kt_character:preview:started",
    PREVIEW_STOPPED             = "kt_character:preview:stopped",
    PREVIEW_REFRESHED           = "kt_character:preview:refreshed",

    -- ── UNION COMPAT ─────────────────────────────────────────────────────
    UNION_SPAWN_APPLY           = "union:spawn:apply",
    UNION_NO_CHARACTERS         = "union:spawn:noCharacters",
    UNION_HAS_CHARACTERS        = "union:spawn:selectCharacter",
}
