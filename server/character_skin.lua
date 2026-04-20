RegisterNetEvent("kt_character:reloadSkin", function(unique_id)
    local src = source

    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    Utils.debug("ReloadSkin pour: " .. unique_id)

    exports.oxmysql:execute(
        [[SELECT c.gender, c.position_x, c.position_y, c.position_z, c.heading,
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

            local appearance = {
                unique_id = unique_id,
                gender = Utils.genderEnumToModel(row.gender),
                model  = Utils.genderEnumToModel(row.gender),
                position = vector3(
                    row.position_x or Config.DEFAULT_SPAWN.x,
                    row.position_y or Config.DEFAULT_SPAWN.y,
                    row.position_z or Config.DEFAULT_SPAWN.z
                ),
                heading = row.heading or Config.DEFAULT_HEADING,
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
                end
            end

            TriggerClientEvent("kt_appearance:apply", src, appearance)
        end
    )
end)