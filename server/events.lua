-- server/events.lua (kt_character)
-- FIX : sélection de ca.face_features et ca.tattoos.
-- FIX : vérification de propriété avant sélection du personnage.
-- FIX : commande openselect restreinte aux admins.

-- =========================================================
-- UNION FLOW
-- =========================================================

AddEventHandler("union:spawn:noCharacters_server", function(src)
    if not src then return end
    TriggerClientEvent("kt_character:openCreator", src)
end)

AddEventHandler("union:spawn:hasCharacters_server", function(src, characters, slots)
    if not src then return end

    if not characters or #characters == 0 then
        TriggerClientEvent("kt_character:openCreator", src)
        return
    end

    TriggerClientEvent("kt_character:openCharacterSelection", src, characters, slots or 3)
end)

-- =========================================================
-- SELECT CHARACTER
-- FIX : vérification que le joueur possède le personnage
-- =========================================================
RegisterNetEvent("kt_character:selectCharacter", function(charId)
    local src = source
    if not src then return end

    if not charId then
        TriggerClientEvent("kt_character:error", src, "ID de personnage invalide")
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Identifiant joueur introuvable")
        return
    end

    Utils.debug("selectCharacter: charId=" .. tostring(charId) .. " src=" .. src, "INFO")

    -- FIX : jointure avec user_character pour vérifier la propriété
    -- FIX : sélectionner aussi face_features et tattoos
    exports.oxmysql:execute([[
        SELECT c.*,
               ca.skin_data,
               ca.face_features,
               ca.tattoos
        FROM characters c
        INNER JOIN user_character uc ON uc.unique_id = c.unique_id
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.id = ?
          AND uc.identifier = ?
        LIMIT 1
    ]],
    { charId, license },
    function(result)

        if not result or #result == 0 then
            -- Peut être introuvable OU appartenir à quelqu'un d'autre
            TriggerClientEvent("kt_character:error", src, "Personnage introuvable ou accès refusé")
            return
        end

        local row = result[1]

        -- Normalisation ped
        local ped_model = row.ped_model
        if ped_model ~= "mp_m_freemode_01" and ped_model ~= "mp_f_freemode_01" then
            ped_model = "mp_m_freemode_01"
        end
        local gender = (ped_model == "mp_f_freemode_01") and "f" or "m"

        row.ped_model = ped_model
        row.gender    = gender
        row.model     = ped_model

        -- Position JSON
        local px, py, pz, hdg
        if row.position then
            local ok, p = pcall(json.decode, tostring(row.position))
            if ok and p and p.x then
                px, py, pz, hdg = p.x, p.y, p.z, p.heading
            end
        end

        row.position = vector3(
            px or Config.DEFAULT_SPAWN.x,
            py or Config.DEFAULT_SPAWN.y,
            pz or Config.DEFAULT_SPAWN.z
        )
        row.heading = hdg or Config.DEFAULT_HEADING

        -- Skin data
        if row.skin_data then
            local ok, skin = pcall(json.decode, row.skin_data)
            if ok and skin then
                row.hair         = skin.hair         or {}
                row.headBlend    = skin.headBlend    or {}
                row.headOverlays = skin.headOverlays or {}
                row.components   = skin.components   or {}
                row.props        = skin.props        or {}
            end
        end

        -- FIX : colonnes dédiées
        if row.face_features then
            local ok, ff = pcall(json.decode, row.face_features)
            row.faceFeatures = (ok and ff) or {}
        else
            row.faceFeatures = {}
        end

        if row.tattoos then
            local ok, tt = pcall(json.decode, row.tattoos)
            row.tattoos = (ok and tt) or {}
        else
            row.tattoos = {}
        end

        -- Sécurité
        row.firstname = row.firstname or ""
        row.lastname  = row.lastname  or ""
        row.job       = row.job       or "unemployed"
        row.job_grade = row.job_grade or 0

        TriggerClientEvent("union:spawn:apply", src, row)
        TriggerEvent("union:spawn:characterSelected", src, row)

        Utils.debug("Personnage sélectionné: " .. row.firstname, "INFO")
    end)
end)

-- =========================================================
-- DEBUG COMMAND
-- FIX : restreinte aux admins via IsPlayerAceAllowed
-- =========================================================
RegisterCommand("openselect", function(src)
    if src == 0 then return end

    -- FIX : vérification ACE admin
    if not IsPlayerAceAllowed(src, "command.openselect") then
        TriggerClientEvent("kt_character:error", src, "Accès refusé")
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute([[
        SELECT c.id, c.unique_id, c.firstname, c.lastname, c.dateofbirth,
               c.ped_model, c.job, c.job_grade, c.health, c.armor
        FROM characters c
        INNER JOIN user_character uc ON uc.unique_id = c.unique_id
        WHERE uc.identifier = ?
        ORDER BY c.id ASC
    ]],
    { license },
    function(characters)
        characters = characters or {}

        for i = 1, #characters do
            local c       = characters[i]
            local pm      = c.ped_model
            if pm ~= "mp_m_freemode_01" and pm ~= "mp_f_freemode_01" then
                pm = "mp_m_freemode_01"
            end
            c.ped_model = pm
            c.gender    = (pm == "mp_f_freemode_01") and "f" or "m"
        end

        TriggerClientEvent("kt_character:openCharacterSelection", src, characters, 3)
    end)
end, false)
