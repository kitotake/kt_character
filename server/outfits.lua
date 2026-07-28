-- server/outfits.lua (kt_character)
-- FIX : vérification propriété dans saveOutfit (via user_character).
-- FIX : vérification propriété dans deleteOutfit (via user_character, pas seulement unique_id).
-- FIX : vérification propriété dans loadOutfit.
-- FIX : vérification permission admin dans saveJobOutfit.

local DEBUG = true

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^3[kt_outfits:%s]^7 %s"):format(level or "INFO", msg))
end

local function trim(s)
    return (s and string.gsub(s, "^%s*(.-)%s*$", "%1")) or ""
end

local function encode(data)
    return json.encode(data or {})
end

local function decode(data)
    if not data then return {} end
    local ok, res = pcall(json.decode, data)
    return ok and res or {}
end

local function validateOutfitData(data)
    if not data then return false, "Données manquantes" end
    if not data.unique_id or data.unique_id == "" then
        return false, "unique_id manquant"
    end
    local name = trim(data.name)
    if name == "" then return false, "Nom invalide" end
    if #name > 50 then return false, "Nom trop long" end
    return true
end

-- =========================================================
-- SAVE OUTFIT
-- FIX : vérification que le joueur possède le unique_id avant INSERT
-- =========================================================
RegisterNetEvent("kt_character:saveOutfit", function(data)
    local src = source

    local ok, err = validateOutfitData(data)
    if not ok then
        TriggerClientEvent("kt_character:error", src, err)
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Identifiant joueur introuvable")
        return
    end

    -- FIX : vérification de propriété avant INSERT
    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then
                debugLog("saveOutfit refusé : joueur " .. src .. " ne possède pas " .. data.unique_id, "WARN")
                TriggerClientEvent("kt_character:error", src, "Accès refusé")
                return
            end

            local outfitName = trim(data.name)
            debugLog(("Save outfit %s"):format(outfitName), "INFO")

            exports.oxmysql:execute([[
                INSERT INTO character_outfits (unique_id, name, components, props)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE components = VALUES(components), props = VALUES(props)
            ]],
            {
                data.unique_id,
                outfitName,
                encode(data.components),
                encode(data.props)
            },
            function(res)
                if res and res.affectedRows and res.affectedRows > 0 then
                    TriggerClientEvent("kt_character:outfitSaved", src, {
                        id   = res.insertId,
                        name = outfitName
                    })
                else
                    TriggerClientEvent("kt_character:error", src, "Erreur sauvegarde tenue")
                end
            end)
        end
    )
end)

-- =========================================================
-- GET OUTFITS
-- =========================================================
RegisterNetEvent("kt_character:getOutfits", function(data)
    local src = source
    if not data or not data.unique_id then return end

    exports.oxmysql:execute([[
        SELECT id, name, components, props, is_job_outfit, job_name, job_grade, created_at
        FROM character_outfits
        WHERE unique_id = ? AND is_job_outfit = 0
        ORDER BY created_at DESC
    ]],
    { data.unique_id },
    function(results)
        results = results or {}
        for i = 1, #results do
            results[i].components = decode(results[i].components)
            results[i].props      = decode(results[i].props)
        end
        TriggerClientEvent("kt_character:outfitsList", src, results)
    end)
end)

-- =========================================================
-- LOAD OUTFIT
-- FIX : vérification que l'outfit appartient au unique_id du joueur
-- =========================================================
RegisterNetEvent("kt_character:loadOutfit", function(data)
    local src = source
    if not data or not data.outfit_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    -- FIX : on joint user_character pour valider la propriété
    exports.oxmysql:execute([[
        SELECT co.*
        FROM character_outfits co
        INNER JOIN user_character uc ON uc.unique_id = co.unique_id
        WHERE co.id = ?
          AND uc.identifier = ?
        LIMIT 1
    ]],
    { data.outfit_id, license },
    function(res)
        if not res or #res == 0 then
            TriggerClientEvent("kt_character:error", src, "Tenue introuvable ou accès refusé")
            return
        end

        local outfit = res[1]
        outfit.components = decode(outfit.components)
        outfit.props      = decode(outfit.props)

        TriggerClientEvent("kt_character:applyOutfit", src, outfit)
    end)
end)

-- =========================================================
-- DELETE OUTFIT
-- FIX : vérification de propriété via user_character (pas seulement unique_id)
-- =========================================================
RegisterNetEvent("kt_character:deleteOutfit", function(data)
    local src = source
    if not data or not data.outfit_id or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Identifiant joueur introuvable")
        return
    end

    -- FIX : vérification propriété via jointure — un joueur ne peut supprimer
    -- que ses propres tenues, même s'il devine un outfit_id appartenant à autrui
    exports.oxmysql:execute([[
        DELETE co FROM character_outfits co
        INNER JOIN user_character uc ON uc.unique_id = co.unique_id
        WHERE co.id = ?
          AND co.unique_id = ?
          AND uc.identifier = ?
    ]],
    { data.outfit_id, data.unique_id, license },
    function(res)
        if res and res.affectedRows and res.affectedRows > 0 then
            TriggerClientEvent("kt_character:outfitDeleted", src, data.outfit_id)
        else
            TriggerClientEvent("kt_character:error", src, "Suppression impossible ou accès refusé")
        end
    end)
end)

-- =========================================================
-- JOB OUTFITS AUTO APPLY
-- =========================================================
AddEventHandler("kt_character:onJobChange", function(src, jobName, jobGrade, uniqueId)
    if not src or not jobName then return end

    exports.oxmysql:execute([[
        SELECT components, props
        FROM character_outfits
        WHERE job_name = ? AND job_grade <= ? AND is_job_outfit = 1
        ORDER BY job_grade DESC
        LIMIT 1
    ]],
    { jobName, jobGrade or 0 },
    function(res)
        if not res or #res == 0 then return end
        local outfit = res[1]
        outfit.components = decode(outfit.components)
        outfit.props      = decode(outfit.props)
        TriggerClientEvent("kt_character:applyOutfit", src, outfit)
    end)
end)

-- =========================================================
-- SAVE JOB OUTFIT (ADMIN)
-- FIX : vérification ACE admin
-- =========================================================
RegisterNetEvent("kt_character:saveJobOutfit", function(data)
    local src = source
    if not data or not data.job_name then return end

    -- FIX : seuls les admins peuvent créer des tenues métier
    if not IsPlayerAceAllowed(src, "command.saveJobOutfit") then
        TriggerClientEvent("kt_character:error", src, "Accès refusé")
        return
    end

    exports.oxmysql:execute([[
        INSERT INTO character_outfits
            (unique_id, name, components, props, is_job_outfit, job_name, job_grade)
        VALUES ('system', ?, ?, ?, 1, ?, ?)
        ON DUPLICATE KEY UPDATE
            components = VALUES(components),
            props      = VALUES(props)
    ]],
    {
        data.name or (data.job_name .. "_grade_" .. (data.job_grade or 0)),
        encode(data.components),
        encode(data.props),
        data.job_name,
        data.job_grade or 0
    })
end)
