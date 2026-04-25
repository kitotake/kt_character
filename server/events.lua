-- server/events.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Pont entre le framework union et kt_character
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Déclenché par union quand le joueur n'a aucun personnage
-- → ouvre le creator
AddEventHandler("union:spawn:noCharacters_server", function(src)
    TriggerClientEvent("kt_character:openCreator", src)
end)

-- Déclenché par union quand le joueur a au moins 1 personnage
-- → ouvre la sélection de personnage
-- Payload attendu : src, characters (table), slots (number)
AddEventHandler("union:spawn:hasCharacters_server", function(src, characters, slots)
    if not characters or #characters == 0 then
        -- Aucun personnage finalement → creator
        TriggerClientEvent("kt_character:openCreator", src)
        return
    end
    TriggerClientEvent("kt_character:openCharacterSelection", src, characters, slots or 3)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SÉLECTION D'UN PERSONNAGE DEPUIS LA NUI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:selectCharacter", function(charId)
    local src = source

    if not charId then
        TriggerClientEvent("kt_character:error", src, "ID de personnage invalide")
        return
    end

    Utils.debug("selectCharacter: charId=" .. tostring(charId) .. " src=" .. src, "INFO")

    -- Charger le personnage depuis la DB
    exports.oxmysql:execute(
        [[SELECT c.*, ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.id = ? LIMIT 1]],
        { charId },
        function(result)
            if not result or #result == 0 then
                TriggerClientEvent("kt_character:error", src, "Personnage introuvable")
                return
            end

            local row = result[1]

            -- Convertir le genre
            row.gender = Utils.genderEnumToModel(row.gender)
            row.model  = row.gender

            -- Décoder la position
            local px, py, pz, hdg
            if row.position then
                local ok, p = pcall(json.decode, tostring(row.position))
                if ok and p and p.x then
                    px, py, pz, hdg = p.x, p.y, p.z, p.heading
                end
            end

            if px then
                row.position = vector3(px, py, pz)
                row.heading  = hdg or row.heading or Config.DEFAULT_HEADING
            else
                row.position = vector3(
                    row.position_x or Config.DEFAULT_SPAWN.x,
                    row.position_y or Config.DEFAULT_SPAWN.y,
                    row.position_z or Config.DEFAULT_SPAWN.z
                )
                row.heading = row.heading or Config.DEFAULT_HEADING
            end

            -- Décoder le skin
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

            -- Appliquer le spawn via union (qui gère le spawn du ped)
            TriggerClientEvent("union:spawn:apply", src, row)

            -- Notifier union que le spawn est confirmé (si besoin)
            TriggerEvent("union:spawn:characterSelected", src, row)

            Utils.debug("Personnage sélectionné: " .. (row.firstname or "?"), "INFO")
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDE SERVEUR : ouvrir la sélection manuellement (debug)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("openselect", function(src)
    if src == 0 then return end -- console

    local license = Identifiers.getLicense(src)
    if not license then return end

    exports.oxmysql:execute(
        [[SELECT c.id, c.unique_id, c.firstname, c.lastname, c.dateofbirth,
                 c.gender, c.job, c.job_grade, c.health, c.armor
          FROM characters c
          WHERE c.identifier = ?
          ORDER BY c.id ASC]],
        { license },
        function(characters)
            characters = characters or {}
            TriggerClientEvent("kt_character:openCharacterSelection", src, characters, 3)
        end
    )
end, false)