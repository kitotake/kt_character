-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - SERVER SCRIPT
-- Intégration Union Framework
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION = "2.0.0"
local DEBUG   = true

-- Position de spawn par défaut (doit correspondre à Config.spawn.defaultPosition dans Union)
local DEFAULT_SPAWN = { x = -268.5, y = -957.8, z = 31.2 }
local DEFAULT_HEADING = 90.0

local function debugLog(message, level)
    if not DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- ─── Mapping gender model ↔ DB ENUM ──────────────────────────────────────
local function modelToGenderEnum(model)
    if model == "mp_f_freemode_01" then return "f" end
    return "m"
end

local function genderEnumToModel(enum)
    if enum == "f" then return "mp_f_freemode_01" end
    return "mp_m_freemode_01"
end

-- ─── Récupérer la license d'un joueur ────────────────────────────────────
local function getPlayerLicense(src)
    -- Essayer d'abord via Union Framework si disponible
    local ok, result = pcall(function()
        return exports["union"]:GetPlayerFromId(src)
    end)
    if ok and result and result.license then
        return result.license
    end

    -- Fallback : lecture directe des identifiers
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            return id
        end
    end
    return nil
end

-- ─── Validation des données ───────────────────────────────────────────────
local function validateCharacterData(data)
    if not data then return false, "Données invalides" end

    if not data.firstname or #data.firstname < 2 then
        return false, "Prénom invalide (minimum 2 caractères)"
    end
    if #data.firstname > 50 then
        return false, "Prénom trop long (maximum 50 caractères)"
    end
    if not data.lastname or #data.lastname < 2 then
        return false, "Nom invalide (minimum 2 caractères)"
    end
    if #data.lastname > 50 then
        return false, "Nom trop long (maximum 50 caractères)"
    end
    if not data.dateofbirth or data.dateofbirth == "" then
        return false, "Date de naissance manquante"
    end

    local year = tonumber(string.sub(tostring(data.dateofbirth), 1, 4))
    local currentYear = tonumber(os.date("%Y"))
    if not year then return false, "Format de date invalide (attendu: YYYY-MM-DD)" end
    if year < 1900 or year > currentYear then return false, "Date de naissance invalide" end
    if (currentYear - year) < 18 then return false, "Vous devez avoir au moins 18 ans" end

    if data.gender ~= "mp_m_freemode_01" and data.gender ~= "mp_f_freemode_01" then
        return false, "Genre invalide"
    end

    return true, "Validation réussie"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CRÉATION D'UN PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source
    local playerName = GetPlayerName(src)
    debugLog("Création de personnage pour " .. playerName, "INFO")

    local isValid, message = validateCharacterData(data)
    if not isValid then
        debugLog("Validation échouée: " .. message, "WARN")
        TriggerClientEvent("kt_character:error", src, message)
        return
    end

    local license = getPlayerLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    -- Générer unique_id
    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = string.format("%s_%d", license:gsub("license:", ""), os.time())
    end

    local genderEnum = modelToGenderEnum(data.gender)

    -- ─── Données skin complètes pour character_appearances ────────────
    local skinData = json.encode({
        gender      = data.gender,
        hair        = data.hair        or { style = 0, color = 0, highlight = 0 },
        headBlend   = data.headBlend   or {},
        faceFeatures= data.faceFeatures or {},
        headOverlays= data.headOverlays or {},
        components  = data.components  or {},
        props       = data.props       or {},
    })

    -- ─── Objet retourné au client ─────────────────────────────────────
    -- IMPORTANT : inclure position + model pour que Union puisse spawner
    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = string.trim(data.firstname),
        lastname    = string.trim(data.lastname),
        dateofbirth = data.dateofbirth,
        gender      = data.gender,       -- model string pour apparence Lua
        genderEnum  = genderEnum,        -- 'm'/'f' pour la DB
        model       = data.gender,       -- ← REQUIS par Union Spawn.apply
        hair        = data.hair         or 0,
        beard       = data.beard        or 0,
        hairColor   = data.hairColor    or 0,
        headBlend   = data.headBlend    or {},
        faceFeatures= data.faceFeatures or {},
        headOverlays= data.headOverlays or {},
        components  = data.components   or {},
        props       = data.props        or {},
        tattoos     = data.tattoos      or {},
        -- ← POSITION DE SPAWN (corrige le bug 0,0,0)
        position    = vector3(DEFAULT_SPAWN.x, DEFAULT_SPAWN.y, DEFAULT_SPAWN.z),
        heading     = DEFAULT_HEADING,
        health      = 200,
        armor       = 0,
        created_at  = os.time(),
    }

    debugLog(
        ("Nouveau personnage: %s %s (ID: %s) | Genre: %s"):format(
            character.firstname, character.lastname,
            character.unique_id, genderEnum
        ), "INFO"
    )

    -- ─── INSERT DB (oxmysql) ─────────────────────────────────────────
    exports.oxmysql:execute(
        [[INSERT INTO characters
            (identifier, unique_id, firstname, lastname, dateofbirth, gender,
             model, position_x, position_y, position_z, heading)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]],
        {
            character.identifier,
            character.unique_id,
            character.firstname,
            character.lastname,
            character.dateofbirth,
            genderEnum,
            character.model,
            DEFAULT_SPAWN.x,
            DEFAULT_SPAWN.y,
            DEFAULT_SPAWN.z,
            DEFAULT_HEADING,
        },
        function(resultChar)
            if not resultChar or resultChar.affectedRows == 0 then
                debugLog("Erreur insertion characters", "ERROR")
                TriggerClientEvent("kt_character:error", src, "Erreur lors de la sauvegarde")
                return
            end

            -- Insérer l'apparence
            exports.oxmysql:execute(
                [[INSERT INTO character_appearances (unique_id, skin_data)
                  VALUES (?, ?)
                ]],
                { character.unique_id, skinData },
                function(resultAppear)
                    if not resultAppear or resultAppear.affectedRows == 0 then
                        debugLog("Erreur insertion character_appearances", "ERROR")
                    else
                        debugLog("Apparence insérée pour " .. character.unique_id, "INFO")
                    end

                    -- ─── Notifier Union Framework ─────────────────────
                    -- Permet à Union de mettre à jour son PlayerManager
                    TriggerEvent("kt_character:onCharacterCreated", src, character)

                    -- Envoyer au client kt_character (ferme le creator, applique le skin)
                    TriggerClientEvent("kt_character:created", src, character)

                    -- ─── Spawner via Union si disponible ──────────────
                    -- Union attend un characterData avec .model et .position
                    local ok = pcall(function()
                        TriggerClientEvent("union:spawn:apply", src, character)
                    end)
                    if not ok then
                        debugLog("Union spawn:apply non disponible, spawn géré par kt_character", "WARN")
                    end
                end
            )
        end
    )

    -- ─── Mode dev sans DB : décommenter si pas de DB ─────────────────
    -- TriggerClientEvent("kt_character:created", src, character)
    -- TriggerClientEvent("union:spawn:apply", src, character)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- RELOAD SKIN — charger l'apparence depuis la DB
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:reloadSkin", function(unique_id)
    local src = source
    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    debugLog("ReloadSkin pour: " .. unique_id, "INFO")

    exports.oxmysql:execute(
        [[SELECT c.gender, c.position_x, c.position_y, c.position_z, c.heading,
                 ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1
        ]],
        { unique_id },
        function(results)
            if not results or #results == 0 then
                debugLog("Skin introuvable pour: " .. unique_id, "WARN")
                return
            end
            local row = results[1]

            local appearance = {
                unique_id = unique_id,
                gender    = genderEnumToModel(row.gender),
                model     = genderEnumToModel(row.gender),
                position  = vector3(
                    row.position_x or DEFAULT_SPAWN.x,
                    row.position_y or DEFAULT_SPAWN.y,
                    row.position_z or DEFAULT_SPAWN.z
                ),
                heading = row.heading or DEFAULT_HEADING,
            }

            -- Décoder skin_data
            if row.skin_data then
                local skin = json.decode(row.skin_data)
                if skin then
                    appearance.hair         = skin.hair
                    appearance.headBlend    = skin.headBlend
                    appearance.faceFeatures = skin.faceFeatures
                    appearance.headOverlays = skin.headOverlays
                    appearance.components   = skin.components
                    appearance.props        = skin.props
                end
            end

            TriggerClientEvent("kt_appearance:apply", src, appearance)
            debugLog("Skin rechargé pour: " .. unique_id, "INFO")
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MISE À JOUR DE L'APPARENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:updateAppearance", function(data)
    local src = source
    if not data or not data.unique_id then return end

    local skinData = json.encode({
        gender       = data.gender,
        hair         = data.hair         or {},
        headBlend    = data.headBlend    or {},
        faceFeatures = data.faceFeatures or {},
        headOverlays = data.headOverlays or {},
        components   = data.components   or {},
        props        = data.props        or {},
        tattoos      = data.tattoos      or {},
    })

    exports.oxmysql:execute(
        "UPDATE character_appearances SET skin_data = ?, updated_at = NOW() WHERE unique_id = ?",
        { skinData, data.unique_id },
        function(result)
            if result and result.affectedRows > 0 then
                debugLog("Apparence mise à jour pour " .. data.unique_id, "INFO")
            else
                debugLog("Aucune ligne mise à jour pour " .. data.unique_id, "WARN")
            end
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ENVOYER L'IDENTIFIER AU NUI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:requestIdentifier", function()
    local src = source
    local license = getPlayerLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end
    TriggerClientEvent("kt_character:sendIdentifier", src, license)
    debugLog("Identifier envoyé à " .. GetPlayerName(src), "INFO")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CHARGER UN PERSONNAGE EXISTANT (pour /loadchar)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:loadCharacter", function(unique_id)
    local src = source
    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "ID invalide")
        return
    end

    exports.oxmysql:execute(
        [[SELECT c.*, ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1
        ]],
        { unique_id },
        function(result)
            if not result or #result == 0 then
                TriggerClientEvent("kt_character:error", src, "Personnage non trouvé")
                return
            end
            local row = result[1]
            row.gender   = genderEnumToModel(row.gender)
            row.model    = row.gender
            row.position = vector3(
                row.position_x or DEFAULT_SPAWN.x,
                row.position_y or DEFAULT_SPAWN.y,
                row.position_z or DEFAULT_SPAWN.z
            )
            row.heading = row.heading or DEFAULT_HEADING

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

            TriggerClientEvent("kt_appearance:update", src, row)
            TriggerClientEvent("union:spawn:apply", src, row)
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BRIDGE UNION → kt_character
-- Quand Union détecte "no characters", ouvre kt_character creator
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("union:spawn:noCharacters_server", function(src)
    -- Ouvre le creator côté client
    TriggerClientEvent("kt_character:openCreator", src)
    debugLog("Ouverture creator pour " .. GetPlayerName(src), "INFO")
end)

-- ─── Mettre à jour le PlayerManager Union après création ─────────────────
AddEventHandler("kt_character:onCharacterCreated", function(src, character)
    local ok, player = pcall(function()
        return exports["union"]:GetPlayerFromId(src)
    end)
    if ok and player then
        -- Injecter le personnage dans Union
        player.currentCharacter = character
        debugLog("Personnage injecté dans Union PlayerManager pour " .. GetPlayerName(src), "INFO")
    end
end)

-- ─── Events lifecycle ─────────────────────────────────────────────────────
AddEventHandler("onServerResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("kt_character v" .. VERSION .. " démarré (intégration Union)", "INFO")
end)

AddEventHandler("onServerResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("kt_character v" .. VERSION .. " arrêté", "INFO")
end)