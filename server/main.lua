-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — SERVER MAIN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CreateThread(function()
    Utils.debug("kt_character v" .. KT.Config.VERSION .. " (server) chargé", "INFO")
end)

-- ── UNION INTEGRATION ─────────────────────────────────────────────────────

AddEventHandler("union:spawn:noCharacters_server", function(src)
    TriggerClientEvent("kt_character:openCreator", src)
end)

AddEventHandler("union:spawn:hasCharacters_server", function(src, characters, slots)
    if not characters or #characters == 0 then
        TriggerClientEvent("kt_character:openCreator", src)
        return
    end
    TriggerClientEvent("kt_character:openCharacterSelection", src, characters, slots or KT.Config.MAX_CHARACTERS)
end)

-- ── IDENTIFIER REQUEST ────────────────────────────────────────────────────

RegisterNetEvent(KT.Events.C2S_REQUEST_IDENTIFIER, function()
    local src     = source
    local license = Identifiers.getLicense(src)
    if not license then return end

    local unique_id = ActiveCharacters[src] and ActiveCharacters[src].unique_id or ""
    TriggerClientEvent(KT.Events.S2C_SEND_IDENTIFIER, src, license, unique_id)
end)

-- ── ADMIN COMMAND ─────────────────────────────────────────────────────────

RegisterCommand("openselect", function(src)
    if src == 0 then return end
    if not IsPlayerAceAllowed(src, "command.openselect") then
        TriggerClientEvent(KT.Events.S2C_ERROR, src, "Accès refusé")
        return
    end

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute([[
        SELECT c.id, c.unique_id, c.firstname, c.lastname, c.dateofbirth,
               c.ped_model, c.job, c.job_grade, c.health, c.armor
        FROM characters c
        INNER JOIN user_character uc ON uc.unique_id = c.unique_id
        WHERE uc.identifier = ?
        ORDER BY c.id ASC
    ]],
    { license },
    function(characters)
        characters = characters or {}
        for _, c in ipairs(characters) do
            c.ped_model = Utils.normalizePedModel(c.ped_model)
            c.gender    = Utils.modelToGender(c.ped_model)
        end
        TriggerClientEvent("kt_character:openCharacterSelection", src, characters, KT.Config.MAX_CHARACTERS)
    end)
end, false)
