-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — SERVER EXPORTS (API publique)
-- Utilisés par kt_clothing, kt_barber, kt_tattoo, kt_dressing, etc.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── DONNÉES PERSONNAGE ────────────────────────────────────────────────────

--- Retourne le unique_id du personnage actif d'un joueur.
exports("Character_GetUniqueId", function(src)
    return ActiveCharacters[src] and ActiveCharacters[src].unique_id
end)

--- Retourne toutes les données du personnage actif.
exports("Character_GetData", function(src)
    return ActiveCharacters[src]
end)

--- Vérifie si un joueur a un personnage actif.
exports("Character_IsActive", function(src)
    return ActiveCharacters[src] ~= nil
end)

-- ── SAUVEGARDE ────────────────────────────────────────────────────────────

--- Sauvegarde l'apparence complète d'un joueur.
--- Utilisé par les ressources qui gèrent toute l'apparence (kt_creation).
exports("Character_SaveAppearance", function(src, appearanceData)
    local unique_id = ActiveCharacters[src] and ActiveCharacters[src].unique_id
    if not unique_id then return false end

    appearanceData.unique_id = unique_id
    TriggerEvent(KT.Events.C2S_UPDATE_APPEARANCE, appearanceData)
    -- Note : on trigger l'event server-side directement (pas network)
    return true
end)

--- Sauvegarde uniquement les vêtements (components + props).
--- Utilisé par kt_clothing, kt_dressing.
exports("Character_SaveClothing", function(src, components, props)
    local unique_id = ActiveCharacters[src] and ActiveCharacters[src].unique_id
    if not unique_id then return false end

    TriggerClientEvent(KT.Events.S2C_APPLY_OUTFIT, src, {
        components = components,
        props      = props,
    })

    exports.oxmysql:execute(
        "SELECT skin_data FROM character_appearances WHERE unique_id = ? LIMIT 1",
        { unique_id },
        function(rows)
            local existing = {}
            if rows and #rows > 0 then existing = Utils.decodeJSON(rows[1].skin_data) end
            existing.components = components or {}
            existing.props      = props      or {}
            exports.oxmysql:execute(
                "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
                { Utils.encodeJSON(existing), unique_id }
            )
        end
    )
    return true
end)

--- Sauvegarde uniquement les tatouages.
--- Utilisé par kt_tattoo.
exports("Character_SaveTattoos", function(src, tattoos)
    local unique_id = ActiveCharacters[src] and ActiveCharacters[src].unique_id
    if not unique_id then return false end

    exports.oxmysql:execute(
        "UPDATE character_appearances SET tattoos = ?, updated_at = NOW() WHERE unique_id = ?",
        { Utils.encodeJSON(tattoos or {}), unique_id }
    )
    TriggerEvent(KT.Events.INTERNAL_TATTOOS_SAVED, src, unique_id)
    return true
end)

--- Sauvegarde uniquement la coiffure.
--- Utilisé par kt_barber.
exports("Character_SaveHair", function(src, hair)
    local unique_id = ActiveCharacters[src] and ActiveCharacters[src].unique_id
    if not unique_id then return false end

    exports.oxmysql:execute(
        "SELECT skin_data FROM character_appearances WHERE unique_id = ? LIMIT 1",
        { unique_id },
        function(rows)
            local existing = {}
            if rows and #rows > 0 then existing = Utils.decodeJSON(rows[1].skin_data) end
            existing.hair = hair or {}
            exports.oxmysql:execute(
                "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
                { Utils.encodeJSON(existing), unique_id }
            )
        end
    )
    return true
end)

-- ── EVENT BUS ─────────────────────────────────────────────────────────────

--- S'abonner à un event interne kt_character.
--- Usage depuis une autre ressource :
---   exports["kt_character"]:On("character:selected", function(src, data) end)
exports("On", function(eventName, cb)
    AddEventHandler(eventName, cb)
end)

--- Déclencher un event interne (pour tests / extensions).
exports("Emit", function(eventName, ...)
    TriggerEvent(eventName, ...)
end)
