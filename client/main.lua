-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN
-- Intégration Union Framework
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION         = "2.0.0"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("character", function()
    if nuiOpen then return end
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
    debugLog("Creator ouvert", "INFO")
end, false)

RegisterCommand("reloadskin", function()
    if not currentUniqueId then
        debugLog("Aucun personnage actif", "WARN")
        return
    end
    TriggerServerEvent("kt_character:reloadSkin", currentUniqueId)
end, false)

RegisterCommand("loadchar", function(_, args)
    if not args[1] then return end
    TriggerServerEvent("kt_character:loadCharacter", args[1])
end, false)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("update", function(data, cb)
    Citizen.CreateThread(function()
        ApplyPreview(data)
    end)
    cb("ok")
end)

RegisterNUICallback("createCharacter", function(data, cb)
    TriggerServerEvent("kt_character:createCharacter", data)
    cb("ok")
end)

RegisterNUICallback("tabChange", function(data, cb)
    local tab = data and data.tab or "identity"
    if tab == "parents" or tab == "features" or tab == "overlays" then
        FocusFace()
    elseif tab == "clothing" then
        FocusBody()
    elseif tab == "tattoos" then
        FocusFull()
    else
        FocusFace()
    end
    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    DestroyCam()
    SetNuiFocus(false, false)
    nuiOpen = false
    cb("ok")
end)

RegisterNUICallback("saveOutfit", function(data, cb)
    if not currentUniqueId then cb("error_no_character") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:saveOutfit", data)
    cb("ok")
end)

RegisterNUICallback("getOutfits", function(_, cb)
    if not currentUniqueId then cb("error_no_character") return end
    TriggerServerEvent("kt_character:getOutfits", { unique_id = currentUniqueId })
    cb("ok")
end)

RegisterNUICallback("loadOutfit", function(data, cb)
    TriggerServerEvent("kt_character:loadOutfit", data)
    cb("ok")
end)

RegisterNUICallback("deleteOutfit", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:deleteOutfit", data)
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS SERVEUR → CLIENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    SendNUIMessage({
        type       = "setIdentifier",
        identifier = license,
        unique_id  = currentUniqueId or "",
    })
end)

-- ─── Personnage créé : applique le skin ET laisse Union gérer le spawn ────
RegisterNetEvent("kt_character:created", function(character)
    debugLog("Personnage créé: " .. character.firstname .. " " .. character.lastname, "INFO")
    currentUniqueId = character.unique_id

    -- Fermer l'UI creator
    DestroyCam()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "close" })
    nuiOpen = false

    -- Appliquer l'apparence complète via appearance.lua
    -- (Union gère le spawn via union:spawn:apply envoyé depuis le serveur)
    Citizen.CreateThread(function()
        Wait(500) -- attendre que Union ait spawné le ped
        ApplyFullAppearance(character)
    end)
end)

-- ─── Ouvrir le creator depuis Union (quand noCharacters) ─────────────────
RegisterNetEvent("kt_character:openCreator", function()
    if nuiOpen then return end
    debugLog("Ouverture creator (demandée par Union)", "INFO")
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
end)

-- ─── Erreur serveur ───────────────────────────────────────────────────────
RegisterNetEvent("kt_character:error", function(msg)
    debugLog("Erreur serveur: " .. tostring(msg), "ERROR")
    SendNUIMessage({ type = "error", message = msg })
end)

-- ─── Tenues ───────────────────────────────────────────────────────────────
RegisterNetEvent("kt_character:outfitSaved", function(outfit)
    SendNUIMessage({ type = "outfitSaved", outfit = outfit })
end)

RegisterNetEvent("kt_character:outfitsList", function(outfits)
    SendNUIMessage({ type = "outfitsList", outfits = outfits })
end)

RegisterNetEvent("kt_character:outfitDeleted", function(outfitId)
    SendNUIMessage({ type = "outfitDeleted", id = outfitId })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INTÉGRATION UNION : écouter le spawn appliqué par Union
-- Quand Union spawne le ped via union:spawn:apply, on ré-applique le skin
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("union:spawn:apply", function(characterData)
    -- Union gère déjà le spawn du ped (SetPlayerModel, NetworkResurrectLocalPlayer)
    -- kt_character doit juste appliquer l'apparence une fois le ped spawné
    if characterData and characterData.unique_id then
        currentUniqueId = characterData.unique_id
        debugLog("Union spawn détecté pour " .. characterData.unique_id .. ", skin en attente...", "INFO")
        Citizen.CreateThread(function()
            -- Attendre que Union ait terminé son spawn (il fait plusieurs Wait internes)
            Wait(1500)
            ApplyFullAppearance(characterData)
        end)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SPAWN → recharger l'apparence automatiquement
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("playerSpawned", function()
    if currentUniqueId then
        TriggerServerEvent("kt_character:reloadSkin", currentUniqueId)
    end
end)

AddEventHandler("playerDropped", function()
    nuiOpen         = false
    currentUniqueId = nil
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DÉMARRAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Citizen.CreateThread(function()
    Wait(1000)
    debugLog("kt_character client v" .. VERSION .. " chargé (intégration Union)", "INFO")
end)