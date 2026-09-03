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

    -- P0.4 : ce handler acceptait n'importe quel unique_id fourni par le
    -- client sans vérifier qu'il appartient au joueur appelant (contrairement
    -- à C2S_LOAD_OUTFIT/C2S_DELETE_OUTFIT juste au-dessus, qui font déjà la
    -- jointure via user_character). Même vérification que le reste du fichier.
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
        end
    )
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

    -- P0.1 : les tenues de métier vivent désormais dans `character_job_outfits`
    -- (table dédiée, sans lien vers un personnage) plutôt que dans
    -- `character_outfits` avec un faux unique_id = 'system'.
    exports.oxmysql:execute([[
        SELECT components, props FROM character_job_outfits
        WHERE job_name = ? AND job_grade <= ?
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

    -- P0.1 : table dédiée (job_name, job_grade), plus de unique_id = 'system'
    -- qui violait la contrainte FK vers `characters` et faisait échouer
    -- l'INSERT silencieusement (aucun callback ne remontait l'erreur).
    exports.oxmysql:execute([[
        INSERT INTO character_job_outfits (job_name, job_grade, name, components, props)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), components = VALUES(components), props = VALUES(props)
    ]],
    {
        data.job_name,
        data.job_grade or 0,
        data.name or (data.job_name .. "_grade_" .. (data.job_grade or 0)),
        Utils.encodeJSON(data.components),
        Utils.encodeJSON(data.props),
    },
    function(res)
        if res and res.affectedRows and res.affectedRows > 0 then
            Utils.debug("Tenue de métier sauvegardée: " .. data.job_name .. " (grade " .. (data.job_grade or 0) .. ")")
            TriggerClientEvent(KT.Events.S2C_SUCCESS, src, "Tenue de métier sauvegardée")
        else
            Utils.debug("Échec sauvegarde tenue de métier: " .. data.job_name, "WARN")
            TriggerClientEvent(KT.Events.S2C_ERROR, src, "Erreur sauvegarde tenue de métier")
        end
    end)
end)