-- server/character_skin.lua (kt_character)
-- FIX #11 : remplacement de position_x/y/z/heading (inexistants) par position JSON
-- FIX #20 : suppression du double handler kt_character:reloadSkin (déjà dans outfits.lua supprimé)

local function decodePosition(raw)
    if not raw then return nil, nil, nil, nil end
    local ok, p = pcall(json.decode, tostring(raw))
    if ok and p and p.x then
        return p.x, p.y, p.z, p.heading
    end
    return nil, nil, nil, nil
end

RegisterNetEvent("kt_character:reloadSkin", function(unique_id)
    local src = source

    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    Utils.debug("ReloadSkin pour: " .. unique_id)

    -- FIX #11 : SELECT position (JSON) au lieu de position_x/y/z/heading
    exports.oxmysql:execute(
        [[SELECT c.gender, c.position,
                 ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1]],
        { unique_id },
        function(results)
            if not results or #results == 0 then
                Utils.debug("Skin introuvable", "WARN")
                return
            end

            local row = results[1]

            local genderModel = Utils.genderEnumToModel(row.gender)

            -- FIX #11 : décoder la position JSON
            local px, py, pz, hdg = decodePosition(row.position)

            local appearance = {
                unique_id = unique_id,
                gender    = genderModel,
                model     = genderModel,
                position  = vector3(
                    px or Config.DEFAULT_SPAWN.x,
                    py or Config.DEFAULT_SPAWN.y,
                    pz or Config.DEFAULT_SPAWN.z
                ),
                heading = hdg or Config.DEFAULT_HEADING,
            }

            if row.skin_data then
                local skin = json.decode(row.skin_data)
                if skin then
                    appearance.hair         = skin.hair
                    appearance.headBlend    = skin.headBlend
                    appearance.faceFeatures = skin.faceFeatures
                    appearance.headOverlays = skin.headOverlays
                    appearance.components   = skin.components
                    appearance.props        = skin.props
                    appearance.tattoos      = skin.tattoos
                end
            end

            TriggerClientEvent("kt_appearance:apply", src, appearance)
        end
    )
end)

-- Handler pour kt_character:requestSkinEdit
RegisterNetEvent("kt_character:requestSkinEdit", function(unique_id)
    local src = source
    if not unique_id then return end

    exports.oxmysql:execute(
        [[SELECT c.gender, ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1]],
        { unique_id },
        function(result)
            if not result or #result == 0 then return end
            local row = result[1]
            local skinData = {}
            if row.skin_data then
                skinData = json.decode(row.skin_data) or {}
            end
            skinData.gender = Utils.genderEnumToModel(row.gender)
            TriggerClientEvent("kt_character:skinEditData", src, skinData)
        end
    )
end)