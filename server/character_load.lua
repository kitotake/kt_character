-- server/character_load.lua (kt_character)
-- FIX : sélection de ca.face_features et ca.tattoos (colonnes dédiées).
-- FIX : suppression du double trigger kt_appearance:update (doublon avec union:spawn:apply).

local function normalizePed(model)
    if model == "mp_f_freemode_01" then
        return "mp_f_freemode_01", "f"
    end
    return "mp_m_freemode_01", "m"
end

local function decodePosition(raw)
    if raw then
        local ok, p = pcall(json.decode, tostring(raw))
        if ok and p and p.x then
            return p.x, p.y, p.z, p.heading
        end
    end
    return nil, nil, nil, nil
end

RegisterNetEvent("kt_character:loadCharacter", function(unique_id)
    local src = source
    if not src then return end

    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "ID invalide")
        return
    end

    -- FIX : on sélectionne aussi face_features et tattoos
    exports.oxmysql:execute([[
        SELECT c.*,
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

        if not result or #result == 0 then
            TriggerClientEvent("kt_character:error", src, "Personnage non trouvé")
            return
        end

        local row = result[1]

        -- Normalisation ped
        local ped_model, gender = normalizePed(row.ped_model)
        row.ped_model = ped_model
        row.gender    = gender
        row.model     = ped_model

        -- Position JSON
        local px, py, pz, hdg = decodePosition(row.position)
        if px then
            row.position = vector3(px, py, pz)
            row.heading  = hdg or Config.DEFAULT_HEADING
        else
            row.position = vector3(Config.DEFAULT_SPAWN.x, Config.DEFAULT_SPAWN.y, Config.DEFAULT_SPAWN.z)
            row.heading  = Config.DEFAULT_HEADING
        end

        -- Skin data (sans faceFeatures/tattoos qui sont dans leurs colonnes)
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

        -- FIX : lecture des colonnes dédiées face_features et tattoos
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

        -- FIX : on n'envoie qu'un seul event ; union:spawn:apply est le responsable du spawn.
        -- kt_appearance:update supprimé car doublon.
        TriggerClientEvent("union:spawn:apply", src, row)
    end)
end)
