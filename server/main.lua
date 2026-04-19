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

-- ─── Utilitaire: trim string ──────────────────────────────────────────────
function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- ─── Mapping gender model ↔ DB ENUM ──────────────────────────────────────
-- DB: ENUM('m','f')  |  Client: "mp_m_freemode_01" / "mp_f_freemode_01"

local function modelToGenderEnum(model)
    if model == "mp_f_freemode_01" then return "f" end
    return "m" -- mp_m_freemode_01 par défaut
end

local function genderEnumToModel(enum)
    if enum == "f" then return "mp_f_freemode_01" end
    return "mp_m_freemode_01"
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
    -- Le client envoie une string "YYYY-MM-DD"
    if not data.dateofbirth or data.dateofbirth == "" then
        return false, "Date de naissance manquante"
    end

    -- FIX: extraire l'année depuis la string "YYYY-MM-DD"
    local year = tonumber(string.sub(tostring(data.dateofbirth), 1, 4))
    local currentYear = tonumber(os.date("%Y")) -- FIX: os.date retourne une string

    if not year then
        return false, "Format de date invalide (attendu: YYYY-MM-DD)"
    end
    if year < 1900 or year > currentYear then
        return false, "Date de naissance invalide"
    end
    -- Vérification âge minimum 18 ans (approximatif sur l'année)
    if (currentYear - year) < 18 then
        return false, "Vous devez avoir au moins 18 ans"
    end

    -- Validation du genre (valeurs envoyées par le client React)
    if data.gender ~= "mp_m_freemode_01" and data.gender ~= "mp_f_freemode_01" then
        return false, "Genre invalide"
    end

    -- Validation des propriétés d'apparence (optionnelles)
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

-- ─── Récupérer la license d'un joueur ────────────────────────────────────
local function getPlayerLicense(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            return id
        end
    end
    return nil
end

-- ─── Création d'un personnage ──────────────────────────────────────────────
RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source
    local playerName = GetPlayerName(src)

    debugLog("Création de personnage pour " .. playerName, "INFO")

    -- Validation
    local isValid, message = validateCharacterData(data)
    if not isValid then
        debugLog("Validation échouée: " .. message, "WARN")
        TriggerClientEvent("kt_character:error", src, message)
        return
    end

    -- License
    local license = getPlayerLicense(src)
    if not license then
        debugLog("Impossible de récupérer la license pour " .. playerName, "ERROR")
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    -- Générer unique_id
    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = string.format("%s_%d", license:gsub("license:", ""), os.time())
    end

    -- FIX: mapper le modèle → ENUM DB ('m' ou 'f')
    local genderEnum = modelToGenderEnum(data.gender)

    -- Données apparence (vont dans character_appearances, PAS dans characters)
    local skinData = json.encode({
        hair      = data.hair      or 0,
        beard     = data.beard     or 0,
        hairColor = data.hairColor or 0,
    })

    -- Objet retourné au client (conserve le format model string)
    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = string.trim(data.firstname),
        lastname    = string.trim(data.lastname),
        dateofbirth = data.dateofbirth,
        gender      = data.gender,       -- model string pour le client Lua
        genderEnum  = genderEnum,        -- 'm'/'f' pour la DB
        hair        = data.hair      or 0,
        beard       = data.beard     or 0,
        hairColor   = data.hairColor or 0,
        created_at  = os.time(),
    }

    debugLog(
        ("Nouveau personnage: %s %s (ID: %s) | Genre DB: %s"):format(
            character.firstname,
            character.lastname,
            character.unique_id,
            genderEnum
        ),
        "INFO"
    )

    -- ─── INTÉGRATION DATABASE (oxmysql) ──────────────────────────────────
    -- FIX: INSERT dans `characters` SANS colonne skin (elle n'existe pas)
    --      puis INSERT dans `character_appearances` pour les données visuelles

    -- exports.oxmysql:execute(
    --     [[INSERT INTO characters
    --         (identifier, unique_id, firstname, lastname, dateofbirth, gender)
    --       VALUES (?, ?, ?, ?, ?, ?)
    --     ]],
    --     {
    --         character.identifier,
    --         character.unique_id,
    --         character.firstname,
    --         character.lastname,
    --         character.dateofbirth,  -- "YYYY-MM-DD" → colonne DATE MySQL ✓
    --         genderEnum,             -- 'm' ou 'f' → ENUM('m','f') ✓
    --     },
    --     function(resultChar)
    --         if not resultChar or resultChar.affectedRows == 0 then
    --             debugLog("Erreur insertion characters", "ERROR")
    --             TriggerClientEvent("kt_character:error", src, "Erreur lors de la sauvegarde")
    --             return
    --         end
    --
    --         -- Insérer les données d'apparence dans character_appearances
    --         exports.oxmysql:execute(
    --             [[INSERT INTO character_appearances (unique_id, skin_data)
    --               VALUES (?, ?)
    --             ]],
    --             { character.unique_id, skinData },
    --             function(resultAppear)
    --                 if not resultAppear or resultAppear.affectedRows == 0 then
    --                     debugLog("Erreur insertion character_appearances", "ERROR")
    --                     -- On trigger quand même le client (perso créé, skin manquant)
    --                 else
    --                     debugLog("Apparence insérée dans character_appearances", "INFO")
    --                 end
    --                 TriggerClientEvent("kt_character:created", src, character)
    --             end
    --         )
    --     end
    -- )

    -- ─── Mode développement (sans DB) ────────────────────────────────────
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

    debugLog("Mise à jour apparence pour " .. playerName .. " (" .. data.unique_id .. ")", "INFO")

    -- FIX: UPDATE dans character_appearances (PAS dans characters.skin)
    local skinData = json.encode({
        hair      = data.hair      or 0,
        beard     = data.beard     or 0,
        hairColor = data.hairColor or 0,
    })

    -- exports.oxmysql:execute(
    --     "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
    --     { skinData, data.unique_id },
    --     function(result)
    --         if result and result.affectedRows > 0 then
    --             debugLog("Apparence mise à jour pour " .. playerName, "INFO")
    --         else
    --             debugLog("Aucune ligne mise à jour (unique_id introuvable?)", "WARN")
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

    local license = getPlayerLicense(src)
    if not license then
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

    -- FIX: JOIN characters + character_appearances pour récupérer tout d'un coup
    -- exports.oxmysql:execute(
    --     [[SELECT c.*, ca.skin_data, ca.face_features, ca.tattoos
    --       FROM characters c
    --       LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
    --       WHERE c.unique_id = ?
    --       LIMIT 1
    --     ]],
    --     { unique_id },
    --     function(result)
    --         if not result or #result == 0 then
    --             debugLog("Personnage introuvable: " .. unique_id, "WARN")
    --             TriggerClientEvent("kt_character:error", src, "Personnage non trouvé")
    --             return
    --         end
    --
    --         local row = result[1]
    --
    --         -- FIX: convertir ENUM 'm'/'f' → model string pour le client Lua
    --         row.gender = genderEnumToModel(row.gender)
    --
    --         -- Décoder skin_data pour injecter les props d'apparence à plat
    --         if row.skin_data then
    --             local skin = json.decode(row.skin_data)
    --             if skin then
    --                 row.hair      = skin.hair
    --                 row.beard     = skin.beard
    --                 row.hairColor = skin.hairColor
    --             end
    --         end
    --
    --         debugLog("Personnage chargé: " .. row.firstname .. " " .. row.lastname, "INFO")
    --         TriggerClientEvent("kt_appearance:update", src, row)
    --
    --         -- Mettre à jour last_played
    --         exports.oxmysql:execute(
    --             "UPDATE characters SET last_played = NOW() WHERE unique_id = ?",
    --             { unique_id }
    --         )
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