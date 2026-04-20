RegisterNetEvent("kt_character:updateAppearance", function(data)
    local src = source

    if not data or not data.unique_id then return end

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
        "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
        { skinData, data.unique_id },
        function(result)
            if result and result.affectedRows > 0 then
                Utils.debug("Apparence mise à jour pour " .. data.unique_id)
            end
        end
    )
end)