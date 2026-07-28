-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — OUTFITS SERVICE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OutfitService = {}

-- ── SAVE ──────────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_SAVE_OUTFIT, function(data)
    local src = source
    local ok, err = Validator.outfitData(data)
    if not ok then TriggerClientEvent(KT.Events.S2C_ERROR, src, err) return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute(
        "SELECT 1 FROM user_character WHERE identifier = ? AND unique_id = ? LIMIT 1",
        { license, data.unique_id },
        function(check)
            if not check or #check == 0 then
                TriggerClientEvent(KT.Events.S2C_ERROR, src, "Accès refusé")
                return
            end

            local name = string.trim(data.name)
            exports.oxmysql:execute([[
                INSERT INTO character_outfits (unique_id, name, components, props)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE components = VALUES(components), props = VALUES(props)
            ]],
            {
                data.unique_id, name,
                Utils.encodeJSON(data.components),
                Utils.encodeJSON(data.props),
            },
            function(res)
                if res and res.affectedRows and res.affectedRows > 0 then
                    TriggerClientEvent(KT.Events.S2C_OUTFIT_SAVED, src, {
                        id = res.insertId, name = name
                    })
                else
                    TriggerClientEvent(KT.Events.S2C_ERROR, src, "Erreur sauvegarde tenue")
                end
            end)
        end
    )
end)

-- ── LIST ──────────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_GET_OUTFITS, function(data)
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
            results[i].components = Utils.decodeJSON(results[i].components)
            results[i].props      = Utils.decodeJSON(results[i].props)
        end
        TriggerClientEvent(KT.Events.S2C_OUTFITS_LIST, src, results)
    end)
end)

-- ── LOAD ──────────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_LOAD_OUTFIT, function(data)
    local src = source
    if not data or not data.outfit_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute([[
        SELECT co.*
        FROM character_outfits co
        INNER JOIN user_character uc ON uc.unique_id = co.unique_id
        WHERE co.id = ? AND uc.identifier = ? LIMIT 1
    ]],
    { data.outfit_id, license },
    function(res)
        if not res or #res == 0 then
            TriggerClientEvent(KT.Events.S2C_ERROR, src, "Tenue introuvable")
            return
        end
        local outfit = res[1]
        outfit.components = Utils.decodeJSON(outfit.components)
        outfit.props      = Utils.decodeJSON(outfit.props)
        TriggerClientEvent(KT.Events.S2C_APPLY_OUTFIT, src, outfit)
        TriggerEvent(KT.Events.INTERNAL_OUTFIT_APPLIED, src, outfit)
    end)
end)

-- ── DELETE ────────────────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_DELETE_OUTFIT, function(data)
    local src = source
    if not data or not data.outfit_id or not data.unique_id then return end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute([[
        DELETE co FROM character_outfits co
        INNER JOIN user_character uc ON uc.unique_id = co.unique_id
        WHERE co.id = ? AND co.unique_id = ? AND uc.identifier = ?
    ]],
    { data.outfit_id, data.unique_id, license },
    function(res)
        if res and res.affectedRows and res.affectedRows > 0 then
            TriggerClientEvent(KT.Events.S2C_OUTFIT_DELETED, src, data.outfit_id)
        else
            TriggerClientEvent(KT.Events.S2C_ERROR, src, "Suppression impossible")
        end
    end)
end)

-- ── JOB OUTFITS ───────────────────────────────────────────────────────────

AddEventHandler(KT.Events.INTERNAL_CHAR_SELECTED, function(src, characterData)
    if not characterData or not characterData.job then return end

    exports.oxmysql:execute([[
        SELECT components, props FROM character_outfits
        WHERE job_name = ? AND job_grade <= ? AND is_job_outfit = 1
        ORDER BY job_grade DESC LIMIT 1
    ]],
    { characterData.job, characterData.job_grade or 0 },
    function(res)
        if not res or #res == 0 then return end
        local outfit = res[1]
        outfit.components = Utils.decodeJSON(outfit.components)
        outfit.props      = Utils.decodeJSON(outfit.props)
        TriggerClientEvent(KT.Events.S2C_APPLY_OUTFIT, src, outfit)
    end)
end)

-- ── SAVE JOB OUTFIT (admin) ───────────────────────────────────────────────

RegisterNetEvent("kt_character:saveJobOutfit", function(data)
    local src = source
    if not data or not data.job_name then return end

    if not IsPlayerAceAllowed(src, "command.saveJobOutfit") then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Accès refusé")
        return
    end

    exports.oxmysql:execute([[
        INSERT INTO character_outfits (unique_id, name, components, props, is_job_outfit, job_name, job_grade)
        VALUES ('system', ?, ?, ?, 1, ?, ?)
        ON DUPLICATE KEY UPDATE components = VALUES(components), props = VALUES(props)
    ]],
    {
        data.name or (data.job_name .. "_grade_" .. (data.job_grade or 0)),
        Utils.encodeJSON(data.components),
        Utils.encodeJSON(data.props),
        data.job_name,
        data.job_grade or 0,
    })
end)
