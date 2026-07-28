-- server/character_skin.lua (kt_character)
-- FIX : sélection de ca.face_features et ca.tattoos.

local function decodePosition(raw)
    if not raw then return nil, nil, nil, nil end
    local ok, p = pcall(json.decode, tostring(raw))
    if ok and p and p.x then
        return p.x, p.y, p.z, p.heading
    end
    return nil, nil, nil, nil
end

-- =========================================================
-- RELOAD SKIN
-- =========================================================
RegisterNetEvent("kt_character:reloadSkin", function(unique_id)
    local src = source
    if not src then return end

    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    Utils.debug("ReloadSkin pour: " .. unique_id)

    -- FIX : sélectionner aussi face_features et tattoos
    exports.oxmysql:execute([[
        SELECT c.ped_model, c.position,
               ca.skin_data,
               ca.face_features,
               ca.tattoos
        FROM characters c
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.unique_id = ?
        LIMIT 1
    ]],
    { unique_id },
    function(results)

        if not results or #results == 0 then
            Utils.debug("Skin introuvable", "WARN")
            return
        end

        local row = results[1]

        local ped_model = row.ped_model
        if ped_model ~= "mp_m_freemode_01" and ped_model ~= "mp_f_freemode_01" then
            ped_model = "mp_m_freemode_01"
        end
        local gender = (ped_model == "mp_f_freemode_01") and "f" or "m"

        local px, py, pz, hdg = decodePosition(row.position)

        local appearance = {
            unique_id = unique_id,
            ped_model = ped_model,
            gender    = gender,
            model     = ped_model,
            position  = vector3(
                px or Config.DEFAULT_SPAWN.x,
                py or Config.DEFAULT_SPAWN.y,
                pz or Config.DEFAULT_SPAWN.z
            ),
            heading   = hdg or Config.DEFAULT_HEADING,
        }

        if row.skin_data then
            local ok, skin = pcall(json.decode, row.skin_data)
            if ok and skin then
                appearance.hair         = skin.hair         or {}
                appearance.headBlend    = skin.headBlend    or {}
                appearance.headOverlays = skin.headOverlays or {}
                appearance.components   = skin.components   or {}
                appearance.props        = skin.props        or {}
            end
        end

        -- FIX : colonnes dédiées
        if row.face_features then
            local ok, ff = pcall(json.decode, row.face_features)
            appearance.faceFeatures = (ok and ff) or {}
        else
            appearance.faceFeatures = {}
        end

        if row.tattoos then
            local ok, tt = pcall(json.decode, row.tattoos)
            appearance.tattoos = (ok and tt) or {}
        else
            appearance.tattoos = {}
        end

        TriggerClientEvent("kt_appearance:apply", src, appearance)
    end)
end)

-- =========================================================
-- SKIN EDIT REQUEST
-- =========================================================
RegisterNetEvent("kt_character:requestSkinEdit", function(unique_id)
    local src = source
    if not src then return end
    if not unique_id then return end

    -- FIX : sélectionner aussi face_features et tattoos
    exports.oxmysql:execute([[
        SELECT c.ped_model,
               ca.skin_data,
               ca.face_features,
               ca.tattoos
        FROM characters c
        LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
        WHERE c.unique_id = ?
        LIMIT 1
    ]],
    { unique_id },
    function(result)

        if not result or #result == 0 then return end

        local row     = result[1]
        local skinData = {}

        if row.skin_data then
            local ok, skin = pcall(json.decode, row.skin_data)
            if ok and skin then skinData = skin end
        end

        local ped_model = row.ped_model
        if ped_model ~= "mp_m_freemode_01" and ped_model ~= "mp_f_freemode_01" then
            ped_model = "mp_m_freemode_01"
        end

        skinData.ped_model = ped_model
        skinData.gender    = (ped_model == "mp_f_freemode_01") and "f" or "m"

        -- FIX : injecter faceFeatures et tattoos depuis leurs colonnes
        if row.face_features then
            local ok, ff = pcall(json.decode, row.face_features)
            skinData.faceFeatures = (ok and ff) or {}
        else
            skinData.faceFeatures = {}
        end

        if row.tattoos then
            local ok, tt = pcall(json.decode, row.tattoos)
            skinData.tattoos = (ok and tt) or {}
        else
            skinData.tattoos = {}
        end

        TriggerClientEvent("kt_character:skinEditData", src, skinData)
    end)
end)
