-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — SHARED CONFIG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

KT = KT or {}
KT.Config = {

    DEBUG   = true,
    VERSION = "3.0.0",

    -- Spawn par défaut si aucune position en BDD
    DEFAULT_SPAWN = vector3(-268.5, -957.8, 31.2),
    DEFAULT_HEADING = 90.0,

    -- Slots de personnages par joueur
    MAX_CHARACTERS = 3,

    -- Age minimum à la création
    MIN_AGE = 18,

    -- Modèles ped autorisés
    ALLOWED_MODELS = {
        "mp_m_freemode_01",
        "mp_f_freemode_01",
    },
}
