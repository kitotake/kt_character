-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — APPEARANCE SERVICE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AppearanceService = {}

-- ── UPDATE APPARENCE COMPLÈTE ─────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_UPDATE_APPEARANCE, function(data)
    local src = source
    if not data or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Identifiant introuvable")
        return
    end

    -- Vérification propriété
    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then
                TriggerClientEvent(KT.Events.S2C_ERROR, src, "Accès refusé")
                return
            end

            local ped_model = Utils.normalizePedModel(data.ped_model or data.gender or "mp_m_freemode_01")

            local skinData = Utils.encodeJSON({
                ped_model    = ped_model,
                gender       = Utils.modelToGender(ped_model),
                hair         = data.hair         or {},
                headBlend    = data.headBlend    or {},
                headOverlays = data.headOverlays or {},
                components   = data.components   or {},
                props        = data.props        or {},
            })

            exports.oxmysql:execute(
                [[UPDATE character_appearances
                  SET skin_data = ?, face_features = ?, tattoos = ?, updated_at = NOW()
                  WHERE unique_id = ?]],
                {
                    skinData,
                    Utils.encodeJSON(data.faceFeatures or {}),
                    Utils.encodeJSON(data.tattoos      or {}),
                    data.unique_id,
                },
                function(result)
                    if result and result.affectedRows and result.affectedRows > 0 then
                        Utils.debug("Apparence mise à jour: " .. data.unique_id)
                        TriggerEvent(KT.Events.INTERNAL_APPEARANCE_SAVED, src, data.unique_id)
                    else
                        Utils.debug("Update apparence échoué: " .. data.unique_id, "WARN")
                    end
                end
            )
        end
    )
end)

-- ── SAVE CLOTHING UNIQUEMENT ──────────────────────────────────────────────
-- Utilisé par kt_clothing, kt_dressing — met à jour seulement components/props

RegisterNetEvent(KT.Events.C2S_SAVE_CLOTHING, function(data)
    local src = source
    if not data or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then return end

            -- On lit le skin_data existant pour ne mettre à jour que components/props
            exports.oxmysql:execute(
                "SELECT skin_data FROM character_appearances WHERE unique_id = ? LIMIT 1",
                { data.unique_id },
                function(rows)
                    local existing = {}
                    if rows and #rows > 0 then
                        existing = Utils.decodeJSON(rows[1].skin_data)
                    end

                    existing.components = data.components or existing.components or {}
                    existing.props      = data.props      or existing.props      or {}

                    exports.oxmysql:execute(
                        "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
                        { Utils.encodeJSON(existing), data.unique_id },
                        function()
                            TriggerEvent(KT.Events.INTERNAL_CLOTHING_SAVED, src, data.unique_id)
                            Utils.debug("Vêtements sauvegardés: " .. data.unique_id)
                        end
                    )
                end
            )
        end
    )
end)

-- ── SAVE TATTOOS UNIQUEMENT ───────────────────────────────────────────────
-- Utilisé par kt_tattoo

RegisterNetEvent(KT.Events.C2S_SAVE_TATTOOS, function(data)
    local src = source
    if not data or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then return end

            exports.oxmysql:execute(
                "UPDATE character_appearances SET tattoos = ?, updated_at = NOW() WHERE unique_id = ?",
                { Utils.encodeJSON(data.tattoos or {}), data.unique_id },
                function()
                    TriggerEvent(KT.Events.INTERNAL_TATTOOS_SAVED, src, data.unique_id)
                    Utils.debug("Tatouages sauvegardés: " .. data.unique_id)
                end
            )
        end
    )
end)

-- ── SAVE HAIR UNIQUEMENT ──────────────────────────────────────────────────
-- Utilisé par kt_barber

RegisterNetEvent(KT.Events.C2S_SAVE_HAIR, function(data)
    local src = source
    if not data or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then return end

            exports.oxmysql:execute(
                "SELECT skin_data FROM character_appearances WHERE unique_id = ? LIMIT 1",
                { data.unique_id },
                function(rows)
                    local existing = {}
                    if rows and #rows > 0 then
                        existing = Utils.decodeJSON(rows[1].skin_data)
                    end
                    existing.hair = data.hair or existing.hair or {}

                    exports.oxmysql:execute(
                        "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
                        { Utils.encodeJSON(existing), data.unique_id },
                        function()
                            Utils.debug("Coiffure sauvegardée: " .. data.unique_id)
                        end
                    )
                end
            )
        end
    )
end)

-- ── RELOAD SKIN (trigger depuis n'importe quelle ressource) ───────────────

RegisterNetEvent("kt_character:reloadSkin", function(unique_id)
    local src = source
    if not unique_id or unique_id == "" then return end

    exports.oxmysql:execute([[
        SELECT c.ped_model, c.position, ca.skin_data, ca.face_features, ca.tattoos
        FROM characters c
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.unique_id = ? LIMIT 1
    ]],
    { unique_id },
    function(results)
        if not results or #results == 0 then return end
        local row = CharacterService.BuildCharacterData(results[1])
        row.unique_id = unique_id
        TriggerClientEvent("kt_appearance:apply", src, row)
    end)
end)

-- ── SKIN EDIT REQUEST ─────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_REQUEST_SKIN_EDIT, function(unique_id)
    local src = source
    if not unique_id then return end

    exports.oxmysql:execute([[
        SELECT c.ped_model, ca.skin_data, ca.face_features, ca.tattoos
        FROM characters c
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.unique_id = ? LIMIT 1
    ]],
    { unique_id },
    function(result)
        if not result or #result == 0 then return end

        local row      = result[1]
        local skinData = Utils.decodeJSON(row.skin_data)
        local ped_model = Utils.normalizePedModel(row.ped_model)

        skinData.ped_model    = ped_model
        skinData.gender       = Utils.modelToGender(ped_model)
        skinData.faceFeatures = Utils.decodeJSON(row.face_features)
        skinData.tattoos      = Utils.decodeJSON(row.tattoos)

        TriggerClientEvent(KT.Events.S2C_SKIN_EDIT_DATA, src, skinData)
    end)
end)
