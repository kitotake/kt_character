-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PATCH unique_id — à remplacer dans kt_character/server/main.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION = "2.0.0"
local DEBUG   = true

local DEFAULT_SPAWN   = { x = -268.5, y = -957.8, z = 31.2 }
local DEFAULT_HEADING = 90.0

local function debugLog(message, level)
    if not DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function modelToGenderEnum(model)
    if model == "mp_f_freemode_01" then return "f" end
    return "m"
end

local function genderEnumToModel(enum)
    if enum == "f" then return "mp_f_freemode_01" end
    return "mp_m_freemode_01"
end

local function getPlayerLicense(src)
    local ok, result = pcall(function()
        return exports["union"]:GetPlayerFromId(src)
    end)
    if ok and result and result.license then return result.license end

    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then return id end
    end
    return nil
end

local function validateCharacterData(data)
    if not data then return false, "Données invalides" end
    if not data.firstname or #data.firstname < 2 then return false, "Prénom invalide" end
    if #data.firstname > 50 then return false, "Prénom trop long" end
    if not data.lastname  or #data.lastname  < 2 then return false, "Nom invalide" end
    if #data.lastname  > 50 then return false, "Nom trop long" end
    if not data.dateofbirth or data.dateofbirth == "" then return false, "Date de naissance manquante" end
    local year = tonumber(string.sub(tostring(data.dateofbirth), 1, 4))
    local currentYear = tonumber(os.date("%Y"))
    if not year then return false, "Format de date invalide (YYYY-MM-DD)" end
    if year < 1900 or year > currentYear then return false, "Date de naissance invalide" end
    if (currentYear - year) < 18 then return false, "Vous devez avoir au moins 18 ans" end
    if data.gender ~= "mp_m_freemode_01" and data.gender ~= "mp_f_freemode_01" then
        return false, "Genre invalide"
    end
    return true, "Validation réussie"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CRÉATION PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source
    debugLog("Création de personnage pour " .. GetPlayerName(src), "INFO")

    local isValid, message = validateCharacterData(data)
    if not isValid then
        TriggerClientEvent("kt_character:error", src, message)
        return
    end

    local license = getPlayerLicense(src)
    if not license then
        TriggerClientEvent("kt_character:error", src, "Erreur d'authentification")
        return
    end

    print("License obtenue: " .. license)
    print("Validation: " .. message)

    -- ✅ CORRIGÉ : unique_id ≤ 32 caractères
    local unique_id = data.unique_id
if not unique_id or unique_id == "" then
    unique_id = "chr_" .. exports['union']:generateUniqueId()
end

    local genderEnum = modelToGenderEnum(data.gender)

    local skinData = json.encode({
        gender       = data.gender,
        hair         = data.hair         or { style = 0, color = 0, highlight = 0 },
        headBlend    = data.headBlend    or {},
        faceFeatures = data.faceFeatures or {},
        headOverlays = data.headOverlays or {},
        components   = data.components  or {},
        props        = data.props        or {},
    })

    local character = {
        identifier   = license,
        unique_id    = unique_id,
        firstname    = string.trim(data.firstname),
        lastname     = string.trim(data.lastname),
        dateofbirth  = data.dateofbirth,
        gender       = data.gender,
        genderEnum   = genderEnum,
        model        = data.gender,
        hair         = data.hair         or 0,
        beard        = data.beard        or 0,
        hairColor    = data.hairColor    or 0,
        headBlend    = data.headBlend    or {},
        faceFeatures = data.faceFeatures or {},
        headOverlays = data.headOverlays or {},
        components   = data.components   or {},
        props        = data.props        or {},
        tattoos      = data.tattoos      or {},
        position     = vector3(DEFAULT_SPAWN.x, DEFAULT_SPAWN.y, DEFAULT_SPAWN.z),
        heading      = DEFAULT_HEADING,
        health       = 200,
        armor        = 0,
        created_at   = os.time(),
    }

    debugLog(("Nouveau personnage: %s %s (ID: %s)"):format(
        character.firstname, character.lastname, character.unique_id), "INFO")

    exports.oxmysql:execute(
        [[INSERT INTO characters
            (identifier, unique_id, firstname, lastname, dateofbirth, gender,
             model, position_x, position_y, position_z, heading)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]],
        {
            character.identifier, character.unique_id,
            character.firstname,  character.lastname,
            character.dateofbirth, genderEnum,
            character.model,
            DEFAULT_SPAWN.x, DEFAULT_SPAWN.y, DEFAULT_SPAWN.z, DEFAULT_HEADING,
        },
        function(resultChar)
            if not resultChar or resultChar.affectedRows == 0 then
                debugLog("Erreur insertion characters", "ERROR")
                TriggerClientEvent("kt_character:error", src, "Erreur lors de la sauvegarde")
                return
            end

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

                    TriggerEvent("kt_character:onCharacterCreated", src, character)
                    TriggerClientEvent("kt_character:created", src, character)

                    local ok = pcall(function()
                        TriggerClientEvent("union:spawn:apply", src, character)
                    end)
                    if not ok then
                        debugLog("Union spawn:apply non disponible", "WARN")
                    end
                end
            )
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- RELOAD SKIN
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
-- UPDATE APPARENCE
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
            end
        end
    )
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- IDENTIFIER NUI
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
-- LOAD CHARACTER (/loadchar)
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
-- BRIDGE UNION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("union:spawn:noCharacters_server", function(src)
    TriggerClientEvent("kt_character:openCreator", src)
    debugLog("Ouverture creator pour " .. GetPlayerName(src), "INFO")
end)

AddEventHandler("kt_character:onCharacterCreated", function(src, character)
    local ok, player = pcall(function()
        return exports["union"]:GetPlayerFromId(src)
    end)
    if ok and player then
        player.currentCharacter = character
        debugLog("Personnage injecté dans Union PlayerManager pour " .. GetPlayerName(src), "INFO")
    end
end)

AddEventHandler("onServerResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("kt_character v" .. VERSION .. " démarré", "INFO")
end)

AddEventHandler("onServerResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    debugLog("kt_character v" .. VERSION .. " arrêté", "INFO")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AJOUT à la fin de kt_character/server/main.lua
-- Handler pour la commande /skin
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- /skin : le client demande les données skin actuelles pour les charger dans l'UI
RegisterNetEvent("kt_character:requestSkinEdit", function(unique_id)
    local src = source
    if not unique_id or unique_id == "" then
        TriggerClientEvent("kt_character:error", src, "unique_id manquant")
        return
    end

    debugLog("Demande d'édition skin pour: " .. unique_id, "INFO")

    exports.oxmysql:execute(
        [[SELECT c.firstname, c.lastname, c.gender, c.dateofbirth,
                 ca.skin_data
          FROM characters c
          LEFT JOIN character_appearances ca ON ca.unique_id = c.unique_id
          WHERE c.unique_id = ? LIMIT 1
        ]],
        { unique_id },
        function(results)
            if not results or #results == 0 then
                TriggerClientEvent("kt_character:error", src, "Personnage introuvable")
                return
            end
            local row = results[1]

            -- Construire l'objet skin pour pré-remplir l'UI
            local skinData = {
                unique_id   = unique_id,
                firstname   = row.firstname,
                lastname    = row.lastname,
                dateofbirth = row.dateofbirth,
                gender      = genderEnumToModel(row.gender),
            }

            if row.skin_data then
                local skin = json.decode(row.skin_data)
                if skin then
                    skinData.hair         = skin.hair
                    skinData.headBlend    = skin.headBlend
                    skinData.faceFeatures = skin.faceFeatures
                    skinData.headOverlays = skin.headOverlays
                    skinData.components   = skin.components
                    skinData.props        = skin.props
                    skinData.tattoos      = skin.tattoos
                end
            end

            TriggerClientEvent("kt_character:skinEditData", src, skinData)
            debugLog("Données skin envoyées pour édition: " .. unique_id, "INFO")
        end
    )
end)