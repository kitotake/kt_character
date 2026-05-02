-- server/character_create.lua (kt_character)
-- FIX #9  : data.gender converti via Utils.modelToGenderEnum() avant INSERT
--           (la colonne SQL est ENUM('m','f'), pas les noms de modèles GTA V)
-- FIX #10 : gender ET model ajoutés dans l'INSERT INTO characters

RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source

    local isValid, msg = Validator.character(data)
    if not isValid then
        TriggerClientEvent("kt_character:error", src, msg)
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then return end

    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = exports['union']:generateUniqueId()
    end

    -- FIX #9 : convertir le gender GTA V → enum BDD ('m' ou 'f')
    local genderEnum  = Utils.modelToGenderEnum(data.gender or "mp_m_freemode_01")
    -- FIX #9 : déduire le model depuis le genre normalisé
    local genderModel = Utils.genderEnumToModel(genderEnum)

    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = string.trim(data.firstname),
        lastname    = string.trim(data.lastname),
        dateofbirth = data.dateofbirth,
        gender      = genderEnum,   -- FIX #9 : 'm' ou 'f' pour la BDD
        model       = genderModel,  -- FIX #10 : modèle GTA V pour le spawn
        hair         = data.hair,
        headBlend    = data.headBlend,
        faceFeatures = data.faceFeatures,
        headOverlays = data.headOverlays,
        components   = data.components,
        props        = data.props,
        tattoos      = data.tattoos,
        position    = Config.DEFAULT_SPAWN,
        heading     = Config.DEFAULT_HEADING,
    }

    local posJson = json.encode({
        x       = Config.DEFAULT_SPAWN.x,
        y       = Config.DEFAULT_SPAWN.y,
        z       = Config.DEFAULT_SPAWN.z,
        heading = Config.DEFAULT_HEADING,
    })

    -- FIX #10 : gender ET model inclus dans l'INSERT
    exports.oxmysql:execute(
        "INSERT INTO characters (identifier, unique_id, firstname, lastname, dateofbirth, gender, model, position) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        {
            character.identifier,
            character.unique_id,
            character.firstname,
            character.lastname,
            character.dateofbirth,
            character.gender,   -- FIX #10
            character.model,    -- FIX #10
            posJson,            -- position JSON initiale
        }
    )

    -- Sauvegarder l'apparence immédiatement
    local skinData = json.encode({
        gender       = genderModel,  -- on stocke le nom complet dans skin_data
        hair         = data.hair         or {},
        headBlend    = data.headBlend    or {},
        faceFeatures = data.faceFeatures or {},
        headOverlays = data.headOverlays or {},
        components   = data.components   or {},
        props        = data.props        or {},
        tattoos      = data.tattoos      or {},
    })

    exports.oxmysql:execute(
        "INSERT INTO character_appearances (unique_id, skin_data) VALUES (?, ?)",
        { character.unique_id, skinData }
    )

    TriggerClientEvent("kt_character:created", src, character)
end)