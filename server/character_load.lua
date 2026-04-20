RegisterNetEvent("kt_character:loadCharacter", function(unique_id)
    local src = source

    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "ID invalide")
        return
    end

    exports.oxmysql:execute(
        [[SELECT c.*, ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1]],
        { unique_id },
        function(result)
            if not result or #result == 0 then
                TriggerClientEvent("kt_character:error", src, "Personnage non trouvé")
                return
            end

            local row = result[1]

            row.gender = Utils.genderEnumToModel(row.gender)
            row.model  = row.gender

            row.position = vector3(
                row.position_x or Config.DEFAULT_SPAWN.x,
                row.position_y or Config.DEFAULT_SPAWN.y,
                row.position_z or Config.DEFAULT_SPAWN.z
            )

            row.heading = row.heading or Config.DEFAULT_HEADING

            if row.skin_data then
                local skin = json.decode(row.skin_data)
                if skin then
                    row.hair         = skin.hair
                    row.headBlend    = skin.headBlend
                    row.faceFeatures = skin.faceFeatures
                    row.headOverlays = skin.headOverlays
                    row.components   = skin.components
                    row.props        = skin.props
                    row.tattoos      = skin.tattoos
                end
            end

            TriggerClientEvent("kt_appearance:update", src, row)
            TriggerClientEvent("union:spawn:apply", src, row)
        end
    )
end)