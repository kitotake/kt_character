-- server/character_update.lua (kt_character)
-- FIX : mise à jour des colonnes face_features et tattoos en plus de skin_data.
-- FIX : vérification que le joueur possède bien le unique_id avant la mise à jour.

RegisterNetEvent("kt_character:updateAppearance", function(data)
    local src = source
    if not src then return end

    if not data or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Identifiant joueur introuvable")
        return
    end

    -- FIX : vérification de propriété — le joueur doit posséder ce unique_id
    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then
                Utils.debug("updateAppearance refusé : joueur " .. src .. " ne possède pas " .. data.unique_id, "WARN")
                TriggerClientEvent("kt_character:error", src, "Accès refusé")
                return
            end

            local ped_model = data.ped_model
            if ped_model ~= "mp_m_freemode_01" and ped_model ~= "mp_f_freemode_01" then
                ped_model = "mp_m_freemode_01"
            end

            local skinData = json.encode({
                ped_model    = ped_model,
                gender       = (ped_model == "mp_f_freemode_01") and "f" or "m",
                hair         = data.hair         or {},
                headBlend    = data.headBlend    or {},
                headOverlays = data.headOverlays or {},
                components   = data.components   or {},
                props        = data.props        or {},
            })

            -- FIX : colonnes dédiées pour faceFeatures et tattoos
            local faceFeaturesJson = json.encode(data.faceFeatures or {})
            local tattoosJson      = json.encode(data.tattoos      or {})

            exports.oxmysql:execute(
                [[UPDATE character_appearances
                  SET skin_data = ?, face_features = ?, tattoos = ?, updated_at = NOW()
                  WHERE unique_id = ?]],
                { skinData, faceFeaturesJson, tattoosJson, data.unique_id },
                function(result)
                    if result and result.affectedRows and result.affectedRows > 0 then
                        Utils.debug("Apparence mise à jour pour " .. data.unique_id)
                    else
                        Utils.debug("Update skin failed: " .. data.unique_id, "WARN")
                    end
                end
            )
        end
    )
end)
