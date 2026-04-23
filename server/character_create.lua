-- server/character_create.lua

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

    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = string.trim(data.firstname),
        lastname    = string.trim(data.lastname),
        dateofbirth = data.dateofbirth,
        gender      = data.gender or "mp_m_freemode_01",  -- ✅ ajouté
        hair        = data.hair,                          -- ✅ skin dès la création
        headBlend    = data.headBlend,
        faceFeatures = data.faceFeatures,
        headOverlays = data.headOverlays,
        components   = data.components,
        props        = data.props,
        tattoos      = data.tattoos,
        position    = Config.DEFAULT_SPAWN,
        heading     = Config.DEFAULT_HEADING,
    }

    exports.oxmysql:execute(
        "INSERT INTO characters (identifier, unique_id, firstname, lastname, dateofbirth) VALUES (?, ?, ?, ?, ?)",
        { character.identifier, character.unique_id, character.firstname, character.lastname, character.dateofbirth }
    )

    -- Sauvegarder l'apparence immédiatement
    local skinData = json.encode({
        gender       = data.gender,
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