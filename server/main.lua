-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - SERVER SCRIPT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION = "1.0.0"
local DEBUG = true

-- ─── Utilité - Debug Log ───────────────────────────────────────────────────
local function debugLog(message, level)
    if not DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

-- ─── Validation des données ───────────────────────────────────────────────
local function validateCharacterData(data)
    if not data then
        return false, "Données invalides"
    end

    -- Validation du prénom
    if not data.firstname or #data.firstname < 2 then
        return false, "Prénom invalide (minimum 2 caractères)"
    end
    if #data.firstname > 50 then
        return false, "Prénom trop long (maximum 50 caractères)"
    end

    -- Validation du nom
    if not data.lastname or #data.lastname < 2 then
        return false, "Nom invalide (minimum 2 caractères)"
    end
    if #data.lastname > 50 then
        return false, "Nom trop long (maximum 50 caractères)"
    end

    -- Validation de la date de naissance
    if not data.dateofbirth then
        return false, "Date de naissance manquante"
    end
    
    local dob = data.dateofbirth
    if dob < 1900 or dob > os.date("%Y") then
        return false, "Date de naissance invalide"
    end

    -- Validation du genre
    if data.gender ~= "mp_m_freemode_01" and data.gender ~= "mp_f_freemode_01" then
        return false, "Genre invalide"
    end

    -- Validation des propriétés optionnelles
    if data.hair and (data.hair < 0 or data.hair > 75) then
        return false, "Coiffure invalide"
    end

    if data.beard and (data.beard < 0 or data.beard > 28) then
        return false, "Barbe invalide"
    end

    if data.hairColor and (data.hairColor < 0 or data.hairColor > 63) then
        return false, "Couleur de cheveux invalide"
    end

    return true, "Validation réussie"
end

-- ─── Création d'un personnage ──────────────────────────────────────────────
RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source
    local playerName = GetPlayerName(src)

    debugLog("Création de personnage pour " .. playerName, "INFO")

    -- Validation des données
    local isValid, message = validateCharacterData(data)
    if not isValid then
        debugLog("Validation échouée: " .. message, "WARN")
        TriggerClientEvent("kt_character:error", src, message)
        return
    end

    -- Récupérer l'identifier FiveM
    local identifiers = GetPlayerIdentifiers(src)
    local license = ""
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            license = id
            break
        end
    end

    if license == "" then
        debugLog("Impossible de récupérer la license pour " .. playerName, "ERROR")
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    -- Générer un unique_id si absent
    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = string.format("%s_%d", license:gsub("license:", ""), os.time())
    end

    -- Construire l'objet personnage
    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = string.trim(data.firstname),
        lastname    = string.trim(data.lastname),
        dateofbirth = data.dateofbirth,
        gender      = data.gender,
        skin        = json.encode({
            hair      = data.hair      or 0,
            beard     = data.beard     or 0,
            hairColor = data.hairColor or 0,
        }),
        created_at  = os.time(),
    }

    debugLog(
        ("Nouveau personnage créé: %s %s (ID: %s) | Genre: %s"):format(
            character.firstname,
            character.lastname,
            character.unique_id,
            character.gender
        ),
        "INFO"
    )

    -- ─── INTÉGRATION DATABASE (exemple oxmysql) ─────────────────────────────
    -- Décommentez et adaptez selon votre système de database
    
    -- exports.oxmysql:execute(
    --     "INSERT INTO characters (identifier, unique_id, firstname, lastname, dateofbirth, gender, skin, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    --     { 
    --         character.identifier, 
    --         character.unique_id, 
    --         character.firstname, 
    --         character.lastname, 
    --         character.dateofbirth, 
    --         character.gender, 
    --         character.skin,
    --         character.created_at
    --     },
    --     function(result)
    --         if result and result.affectedRows > 0 then
    --             debugLog("Personnage inséré en base de données", "INFO")
    --             TriggerClientEvent("kt_character:created", src, character)
    --         else
    --             debugLog("Erreur lors de l'insertion en base de données", "ERROR")
    --             TriggerClientEvent("kt_character:error", src, "Erreur lors de la sauvegarde")
    --         end
    --     end
    -- )

    -- ─── Mode développement: trigger directement le client ──────────────────
    TriggerClientEvent("kt_character:created", src, character)
end)

-- ─── Mise à jour de l'apparence ────────────────────────────────────────────
RegisterNetEvent("kt_character:updateAppearance", function(data)
    local src = source
    local playerName = GetPlayerName(src)

    if not data or not data.unique_id then
        debugLog("Données d'apparence invalides pour " .. playerName, "WARN")
        return
    end

    debugLog("Mise à jour de l'apparence pour " .. playerName, "INFO")

    -- ─── INTÉGRATION DATABASE (exemple oxmysql) ─────────────────────────────
    -- Décommentez et adaptez selon votre système de database
    
    -- exports.oxmysql:execute(
    --     "UPDATE characters SET skin = ? WHERE unique_id = ?",
    --     { json.encode(data), data.unique_id },
    --     function(result)
    --         if result and result.affectedRows > 0 then
    --             debugLog("Apparence mise à jour pour " .. playerName, "INFO")
    --         else
    --             debugLog("Erreur lors de la mise à jour de l'apparence", "ERROR")
    --         end
    --     end
    -- )

    debugLog("Apparence enregistrée (non persistée en dev)", "INFO")
end)

-- ─── Envoyer l'identifier au NUI ───────────────────────────────────────────
RegisterNetEvent("kt_character:requestIdentifier", function()
    local src = source
    local playerName = GetPlayerName(src)

    debugLog("Demande d'identifier pour " .. playerName, "INFO")

    local identifiers = GetPlayerIdentifiers(src)
    local license = ""
    
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            license = id
            break
        end
    end

    if license == "" then
        debugLog("Impossible de récupérer la license pour " .. playerName, "ERROR")
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    TriggerClientEvent("kt_character:sendIdentifier", src, license)
    debugLog("Identifier envoyé à " .. playerName, "INFO")
end)

-- ─── Charger un personnage existant ────────────────────────────────────────
RegisterNetEvent("kt_character:loadCharacter", function(unique_id)
    local src = source
    local playerName = GetPlayerName(src)

    if not unique_id or unique_id == "" then
        debugLog("Chargement impossible: unique_id invalide pour " .. playerName, "WARN")
        TriggerClientEvent("kt_character:error", src, "ID invalide")
        return
    end

    debugLog("Chargement du personnage " .. unique_id .. " pour " .. playerName, "INFO")

    -- ─── INTÉGRATION DATABASE (exemple oxmysql) ─────────────────────────────
    -- Décommentez et adaptez selon votre système de database
    
    -- exports.oxmysql:execute(
    --     "SELECT * FROM characters WHERE unique_id = ?",
    --     { unique_id },
    --     function(result)
    --         if result and #result > 0 then
    --             local character = result[1]
    --             debugLog("Personnage chargé: " .. character.firstname .. " " .. character.lastname, "INFO")
    --             TriggerClientEvent("kt_appearance:update", src, character)
    --         else
    --             debugLog("Personnage introuvable", "WARN")
    --             TriggerClientEvent("kt_character:error", src, "Personnage non trouvé")
    --         end
    --     end
    -- )
end)

-- ─── Event de démarrage ────────────────────────────────────────────────────
AddEventHandler("onServerResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("Resource kt_character v" .. VERSION .. " démarrée", "INFO")
end)

-- ─── Event d'arrêt ────────────────────────────────────────────────────────
AddEventHandler("onServerResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("Resource kt_character v" .. VERSION .. " arrêtée", "INFO")
end)

-- ─── Utilitaire: trim string ──────────────────────────────────────────────
function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end