-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — CHARACTER SERVICE (CRUD)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CharacterService = {}

-- Table des personnages actifs { [src] = characterData }
ActiveCharacters = {}

-- ── CREATION ─────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_CREATE_CHARACTER, function(data)
    local src = source
    local isValid, msg = Validator.character(data)
    if not isValid then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, msg)
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Identifiant joueur introuvable")
        return
    end

    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = Utils.generateUUID()
    end

    if not Utils.isValidDate(tostring(data.dateofbirth or "")) then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Date de naissance invalide")
        return
    end

    local pedModel  = Utils.normalizePedModel(data.gender or "mp_m_freemode_01")
    local firstname = string.trim(data.firstname)
    local lastname  = string.trim(data.lastname)
    local dateStr   = tostring(data.dateofbirth)

    local posJson = Utils.encodeJSON({
        x       = KT.Config.DEFAULT_SPAWN.x,
        y       = KT.Config.DEFAULT_SPAWN.y,
        z       = KT.Config.DEFAULT_SPAWN.z,
        heading = KT.Config.DEFAULT_HEADING,
    })

    -- INSERT characters
    exports.oxmysql:execute(
        [[INSERT INTO characters (unique_id, firstname, lastname, dateofbirth, ped_model, position)
          VALUES (?, ?, ?, ?, ?, ?)]],
        { unique_id, firstname, lastname, dateStr, pedModel, posJson },
        function(res1)
            if not res1 or (res1.affectedRows and res1.affectedRows == 0) then
                TriggerClientEvent(KT.Events.S2C_ERROR, src, "Erreur création personnage")
                return
            end

            exports.oxmysql:execute(
                [[INSERT IGNORE INTO user_character (identifier, unique_id) VALUES (?, ?)]],
                { license, unique_id },
                function()
                    local skinData = Utils.encodeJSON({
                        gender       = pedModel,
                        hair         = data.hair         or {},
                        headBlend    = data.headBlend    or {},
                        headOverlays = data.headOverlays or {},
                        components   = data.components   or {},
                        props        = data.props        or {},
                    })
                    local faceFeaturesJson = Utils.encodeJSON(data.faceFeatures or {})
                    local tattoosJson      = Utils.encodeJSON(data.tattoos      or {})

                    exports.oxmysql:execute(
                        [[INSERT INTO character_appearances (unique_id, skin_data, face_features, tattoos)
                          VALUES (?, ?, ?, ?)]],
                        { unique_id, skinData, faceFeaturesJson, tattoosJson },
                        function()
                            local character = {
                                unique_id   = unique_id,
                                firstname   = firstname,
                                lastname    = lastname,
                                dateofbirth = dateStr,
                                ped_model   = pedModel,
                                position    = vector3(
                                    KT.Config.DEFAULT_SPAWN.x,
                                    KT.Config.DEFAULT_SPAWN.y,
                                    KT.Config.DEFAULT_SPAWN.z
                                ),
                                heading     = KT.Config.DEFAULT_HEADING,
                            }

                            Utils.debug("Personnage créé: " .. firstname .. " (" .. unique_id .. ")")
                            TriggerClientEvent(KT.Events.S2C_CREATED, src, character)
                            TriggerEvent(KT.Events.INTERNAL_CHAR_CREATED, src, character)
                        end
                    )
                end
            )
        end
    )
end)

-- ── SELECTION ─────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_SELECT_CHARACTER, function(charId)
    local src = source
    if not charId then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "ID invalide")
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Identifiant joueur introuvable")
        return
    end

    exports.oxmysql:execute([[
        SELECT c.*, ca.skin_data, ca.face_features, ca.tattoos
        FROM characters c
        INNER JOIN user_character uc ON uc.unique_id = c.unique_id
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.id = ? AND uc.identifier = ?
        LIMIT 1
    ]],
    { charId, license },
    function(result)
        if not result or #result == 0 then
            TriggerClientEvent(KT.Events.S2C_ERROR, src, "Personnage introuvable ou accès refusé")
            return
        end

        local row = CharacterService.BuildCharacterData(result[1])
        ActiveCharacters[src] = row

        TriggerClientEvent(KT.Events.UNION_SPAWN_APPLY, src, row)
        TriggerEvent(KT.Events.INTERNAL_CHAR_SELECTED, src, row)
        Utils.debug("Personnage sélectionné: " .. row.firstname .. " (src:" .. src .. ")")
    end)
end)

-- ── HELPERS ───────────────────────────────────────────────────────────────

function CharacterService.BuildCharacterData(row)
    local ped_model = Utils.normalizePedModel(row.ped_model)
    local gender    = Utils.modelToGender(ped_model)

    row.ped_model = ped_model
    row.gender    = gender
    row.model     = ped_model

    -- Position
    if row.position then
        local ok, p = pcall(json.decode, tostring(row.position))
        if ok and p and p.x then
            row.position = vector3(p.x, p.y, p.z)
            row.heading  = p.heading or KT.Config.DEFAULT_HEADING
        else
            row.position = KT.Config.DEFAULT_SPAWN
            row.heading  = KT.Config.DEFAULT_HEADING
        end
    else
        row.position = KT.Config.DEFAULT_SPAWN
        row.heading  = KT.Config.DEFAULT_HEADING
    end

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

    -- Colonnes dédiées
    row.faceFeatures = Utils.decodeJSON(row.face_features)
    row.tattoos      = Utils.decodeJSON(row.tattoos)

    -- Défauts
    row.firstname = row.firstname or ""
    row.lastname  = row.lastname  or ""
    row.job       = row.job       or "unemployed"
    row.job_grade = row.job_grade or 0

    return row
end

AddEventHandler("playerDropped", function()
    local src = source
    ActiveCharacters[src] = nil
end)
