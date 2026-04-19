-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT SCRIPT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION = "1.0.0"
local DEBUG = true
local nuiOpen = false
local currentCharacterId = nil

-- ─── Utilité - Debug Log ───────────────────────────────────────────────────
local function debugLog(message, level)
    if not DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

-- ─── Ouvrir le Character Creator ──────────────────────────────────────────
RegisterCommand("character", function(source, args, rawCommand)
    if nuiOpen then
        debugLog("Character creator déjà ouvert", "WARN")
        return
    end

    nuiOpen = true
    debugLog("Ouverture du character creator", "INFO")

    -- Demander l'identifier au serveur
    TriggerServerEvent("kt_character:requestIdentifier")

    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
end, false)

-- ─── Recevoir l'identifier depuis le serveur ──────────────────────────────
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    debugLog("Identifier reçu du serveur", "INFO")
    
    -- Injecter dans le contexte window du NUI
    SendNUIMessage({
        type       = "setIdentifier",
        identifier = license,
        unique_id  = "" -- sera généré côté serveur
    })
end)

-- ─── NUI Callbacks ────────────────────────────────────────────────────────

-- Mise à jour de l'apparence en temps réel (preview)
RegisterNUICallback("update", function(data, cb)
    local ped = PlayerPedId()
    debugLog("Mise à jour de l'apparence (preview)", "DEBUG")

    if not ped or ped == 0 then
        debugLog("PED invalide pour update", "ERROR")
        cb("error")
        return
    end

    -- Changer le modèle si nécessaire
    if data.gender then
        local model = data.gender == "mp_f_freemode_01"
            and GetHashKey("mp_f_freemode_01")
            or  GetHashKey("mp_m_freemode_01")

        if GetEntityModel(ped) ~= model then
            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) and timeout < 1000 do
                Wait(0)
                timeout = timeout + 1
            end

            if HasModelLoaded(model) then
                SetPlayerModel(PlayerId(), model)
                ped = PlayerPedId()
            else
                debugLog("Impossible de charger le modèle: " .. tostring(model), "ERROR")
            end
        end
    end

    -- Cheveux
    if data.hair ~= nil then
        SetPedComponentVariation(ped, 2, data.hair, 0, 0)
    end
    if data.hairColor ~= nil then
        SetPedHairColor(ped, data.hairColor, 0)
    end

    -- Barbe
    if data.beard ~= nil then
        SetPedHeadOverlay(ped, 1, data.beard, 1.0)
    end

    cb("ok")
end)

-- Création finale du personnage
RegisterNUICallback("createCharacter", function(data, cb)
    debugLog("Demande de création de personnage", "INFO")
    TriggerServerEvent("kt_character:createCharacter", data)
    cb("ok")
end)

-- ─── Personnage créé (retour serveur) ──────────────────────────────────────
RegisterNetEvent("kt_character:created", function(character)
    debugLog("Personnage créé avec succès", "INFO")

    if not character then
        debugLog("Données de personnage invalides", "ERROR")
        return
    end

    -- Appliquer le modèle définitif
    local model = character.gender == "mp_f_freemode_01"
        and GetHashKey("mp_f_freemode_01")
        or  GetHashKey("mp_m_freemode_01")

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 1000 do
        Wait(0)
        timeout = timeout + 1
    end

    if HasModelLoaded(model) then
        SetPlayerModel(PlayerId(), model)
        currentCharacterId = character.unique_id
    else
        debugLog("Impossible de charger le modèle final", "ERROR")
    end

    -- Fermer l'interface
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    nuiOpen = false

    -- Notification
    local msg = string.format("Bienvenue, %s %s!", character.firstname, character.lastname)
    debugLog(msg, "INFO")
    
    -- Exemple avec ox_lib (décommentez si disponible)
    -- exports['ox_lib']:notify({
    --     title = "Succès",
    --     description = msg,
    --     type = 'success',
    --     duration = 3000
    -- })
end)

-- ─── Erreur serveur ──────────────────────────────────────────────────────
RegisterNetEvent("kt_character:error", function(msg)
    debugLog("Erreur serveur: " .. msg, "ERROR")
    SendNUIMessage({ 
        type = "error", 
        message = msg 
    })
end)

-- ─── Fermer le UI avec Escape ───────────────────────────────────────────
RegisterNUICallback("close", function(_, cb)
    debugLog("Fermeture du character creator", "INFO")
    SetNuiFocus(false, false)
    nuiOpen = false
    cb("ok")
end)

-- ─── Application de l'apparence complète ──────────────────────────────────
local function applyAppearance(data)
    local ped = PlayerPedId()
    
    if not ped or ped == 0 then
        debugLog("PED invalide pour applyAppearance", "ERROR")
        return
    end

    debugLog("Application de l'apparence complète", "DEBUG")

    -- Modèle
    if data.gender then
        local model = data.gender == "mp_f_freemode_01"
            and GetHashKey("mp_f_freemode_01")
            or  GetHashKey("mp_m_freemode_01")

        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 1000 do
            Wait(0)
            timeout = timeout + 1
        end

        if HasModelLoaded(model) then
            SetPlayerModel(PlayerId(), model)
            ped = PlayerPedId()
        end
    end

    -- Blend face (parents)
    if data.parents then
        SetPedHeadBlendData(
            ped,
            data.parents.mother, data.parents.father, 0,
            data.parents.mother, data.parents.father, 0,
            data.mixShape or 0.5, data.mixSkin or 0.5, 0.0,
            false
        )
    end

    -- Cheveux
    if data.hair ~= nil then
        SetPedComponentVariation(ped, 2, data.hair, 0, 0)
        if data.hairColor then
            SetPedHairColor(ped, data.hairColor, 0)
        end
    end

    -- Barbe
    if data.beard ~= nil then
        SetPedHeadOverlay(ped, 1, data.beard, 1.0)
    end
end

RegisterNetEvent("kt_appearance:update", applyAppearance)

-- ─── Charger un personnage ────────────────────────────────────────────────
RegisterCommand("loadchar", function(source, args, rawCommand)
    if not args[1] then
        debugLog("Usage: /loadchar [unique_id]", "WARN")
        return
    end

    local uniqueId = args[1]
    debugLog("Chargement du personnage: " .. uniqueId, "INFO")
    TriggerServerEvent("kt_character:loadCharacter", uniqueId)
end, false)

-- ─── Event de joueur spawnant ─────────────────────────────────────────────
AddEventHandler("playerSpawned", function()
    debugLog("Joueur spawné", "INFO")
end)

-- ─── Event de déconnexion ────────────────────────────────────────────────
AddEventHandler("playerDropped", function(reason)
    debugLog("Joueur déconnecté: " .. (reason or "raison inconnue"), "INFO")
    nuiOpen = false
    currentCharacterId = nil
end)

-- ─── Informations au démarrage ────────────────────────────────────────────
Citizen.CreateThread(function()
    Wait(1000)
    debugLog("Client kt_character v" .. VERSION .. " chargé", "INFO")
    debugLog("Utilisez /character pour ouvrir le creator", "INFO")
end)