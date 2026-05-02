-- server/outfits.lua (kt_character)
-- FIX #20 : suppression du double RegisterNetEvent("kt_character:reloadSkin")
--           qui était aussi déclaré dans character_skin.lua
--           Les handlers dupliqués causent une exécution double et des comportements imprévisibles

local DEBUG = true

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^3[kt_outfits:%s]^7 %s"):format(level or "INFO", msg))
end

local function getPlayerLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(id, 1, 8) == "license:" then return id end
    end
    return nil
end

local function validateOutfitData(data)
    if not data then return false, "Données manquantes" end
    if not data.unique_id or data.unique_id == "" then
        return false, "unique_id manquant"
    end
    if not data.name or #string.trim(data.name) < 1 then
        return false, "Nom de tenue invalide"
    end
    if #string.trim(data.name) > 50 then
        return false, "Nom trop long (max 50)"
    end
    return true, "ok"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SAUVEGARDER UNE TENUE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:saveOutfit", function(data)
    local src = source

    local isValid, errMsg = validateOutfitData(data)
    if not isValid then
        debugLog("saveOutfit refusé: " .. errMsg, "WARN")
        TriggerClientEvent("kt_character:error", src, errMsg)
        return
    end

    local license = getPlayerLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    local outfitName = string.trim(data.name)
    local components = data.components and json.encode(data.components) or "{}"
    local props      = data.props      and json.encode(data.props)      or "{}"

    debugLog(("Sauvegarde tenue '%s' pour %s"):format(outfitName, GetPlayerName(src)), "INFO")

    exports.oxmysql:execute(
        [[INSERT INTO character_outfits
            (unique_id, name, components, props)
          VALUES (?, ?, ?, ?)
        ]],
        { data.unique_id, outfitName, components, props },
        function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                debugLog("Tenue sauvegardée (ID " .. (result.insertId or "?") .. ")", "INFO")
                TriggerClientEvent("kt_character:outfitSaved", src, {
                    id   = result.insertId,
                    name = outfitName,
                })
            else
                TriggerClientEvent("kt_character:error", src, "Erreur lors de la sauvegarde")
            end
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- RÉCUPÉRER LES TENUES D'UN PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:getOutfits", function(data)
    local src = source

    if not data or not data.unique_id then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    debugLog("Chargement des tenues pour: " .. data.unique_id, "INFO")

    exports.oxmysql:execute(
        [[SELECT id, name, components, props, is_job_outfit, job_name, job_grade, created_at
          FROM character_outfits
          WHERE unique_id = ? AND is_job_outfit = 0
          ORDER BY created_at DESC
        ]],
        { data.unique_id },
        function(results)
            if not results then
                TriggerClientEvent("kt_character:outfitsList", src, {})
                return
            end

            for _, row in ipairs(results) do
                row.components = row.components and json.decode(row.components) or {}
                row.props      = row.props      and json.decode(row.props)      or {}
            end

            TriggerClientEvent("kt_character:outfitsList", src, results)
            debugLog(#results .. " tenues chargées", "INFO")
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CHARGER UNE TENUE (par ID)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:loadOutfit", function(data)
    local src = source

    if not data or not data.outfit_id then
        TriggerClientEvent("kt_character:error", src, "ID de tenue manquant")
        return
    end

    debugLog("Chargement tenue ID: " .. tostring(data.outfit_id), "INFO")

    exports.oxmysql:execute(
        "SELECT * FROM character_outfits WHERE id = ? LIMIT 1",
        { data.outfit_id },
        function(results)
            if not results or #results == 0 then
                TriggerClientEvent("kt_character:error", src, "Tenue introuvable")
                return
            end
            local outfit = results[1]
            outfit.components = outfit.components and json.decode(outfit.components) or {}
            outfit.props      = outfit.props      and json.decode(outfit.props)      or {}
            TriggerClientEvent("kt_character:applyOutfit", src, outfit)
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SUPPRIMER UNE TENUE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:deleteOutfit", function(data)
    local src = source

    if not data or not data.outfit_id or not data.unique_id then
        TriggerClientEvent("kt_character:error", src, "Données manquantes")
        return
    end

    debugLog("Suppression tenue ID: " .. tostring(data.outfit_id), "INFO")

    exports.oxmysql:execute(
        "DELETE FROM character_outfits WHERE id = ? AND unique_id = ?",
        { data.outfit_id, data.unique_id },
        function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                debugLog("Tenue supprimée", "INFO")
                TriggerClientEvent("kt_character:outfitDeleted", src, data.outfit_id)
            else
                TriggerClientEvent("kt_character:error", src, "Suppression impossible")
            end
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TENUES JOB (uniformes selon métier + grade)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("kt_character:onJobChange", function(src, jobName, jobGrade, uniqueId)
    if not src or not jobName or not uniqueId then return end

    debugLog(("Job change: %s → %s (grade %d)"):format(
        tostring(uniqueId), jobName, jobGrade or 0
    ), "INFO")

    exports.oxmysql:execute(
        [[SELECT components, props
          FROM character_outfits
          WHERE job_name = ? AND job_grade <= ? AND is_job_outfit = 1
          ORDER BY job_grade DESC
          LIMIT 1
        ]],
        { jobName, jobGrade or 0 },
        function(results)
            if not results or #results == 0 then return end
            local outfit = results[1]
            outfit.components = outfit.components and json.decode(outfit.components) or {}
            outfit.props      = outfit.props      and json.decode(outfit.props)      or {}
            TriggerClientEvent("kt_character:applyOutfit", src, outfit)
            debugLog(("Uniforme %s grade %d appliqué"):format(jobName, jobGrade or 0), "INFO")
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SAUVEGARDER UN UNIFORME JOB (admin uniquement)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:saveJobOutfit", function(data)
    local src = source

    if not data or not data.job_name or not data.job_grade then
        TriggerClientEvent("kt_character:error", src, "Données uniforme invalides")
        return
    end

    local components = data.components and json.encode(data.components) or "{}"
    local props      = data.props      and json.encode(data.props)      or "{}"

    debugLog(("Sauvegarde uniforme %s grade %d"):format(data.job_name, data.job_grade), "INFO")

    exports.oxmysql:execute(
        [[INSERT INTO character_outfits
            (unique_id, name, components, props, is_job_outfit, job_name, job_grade)
          VALUES ('system', ?, ?, ?, 1, ?, ?)
          ON DUPLICATE KEY UPDATE components = VALUES(components), props = VALUES(props)
        ]],
        {
            data.name or (data.job_name .. "_grade_" .. data.job_grade),
            components,
            props,
            data.job_name,
            data.job_grade,
        },
        function(result)
            if result and result.affectedRows and result.affectedRows > 0 then
                debugLog("Uniforme enregistré", "INFO")
            end
        end
    )
end)

-- FIX #20 : kt_character:reloadSkin SUPPRIMÉ ICI
-- Il est défini dans character_skin.lua — un seul handler suffit