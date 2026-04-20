-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN v2.0.2
-- Fix close UI + freeze + commande /skin
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION         = "2.0.2"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER : fermer proprement le creator
-- Appelé par le NUI callback "close" (déclenché par Creator.tsx après submit)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function closeCreator()
    -- Détruire la caméra scriptée (inclut FreezeEntityPosition false)
    if DestroyCharacterCam then
        DestroyCharacterCam()
    end

    -- Force unfreeze sur le ped ACTUEL (au cas où le modèle a changé)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    -- Libérer le focus NUI
    SetNuiFocus(false, false)

    nuiOpen = false
    debugLog("Creator fermé proprement", "INFO")
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

-- /skin : ouvrir le creator en mode modification (même UI, skin pré-chargé)
RegisterCommand("skin", function()
    if nuiOpen then return end
    if not currentUniqueId then
        TriggerEvent("chat:addMessage", {
            color = {255, 100, 100},
            args = {"[SKIN]", "Aucun personnage actif. Sélectionnez un personnage d'abord."}
        })
        return
    end
    nuiOpen = true
    TriggerServerEvent("kt_character:requestSkinEdit", currentUniqueId)
    CreateCharacterCam()
    SetNuiFocus(true, true)
    debugLog("Mode skin ouvert pour: " .. currentUniqueId, "INFO")
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

-- Focus caméra selon l'onglet
RegisterNUICallback("tabChange", function(data, cb)
    local tab = data and data.tab or "identity"
    if tab == "parents" or tab == "features" or tab == "overlays" then
        FocusFace()
    elseif tab == "hair" then
        FocusHair()
    elseif tab == "clothing" then
        FocusBody()
    elseif tab == "tattoos" then
        FocusFull()
    else
        FocusFace()
    end
    cb("ok")
end)

RegisterNUICallback("cameraControl", function(data, cb)
    local action = data and data.action or ""
    if HandleCameraControl then
        HandleCameraControl(action)
    end
    cb("ok")
end)

-- FIX PRINCIPAL : Creator.tsx appelle nuiFetch("close") après le submit
-- C'est ici que l'UI se ferme proprement, qu'il y ait eu erreur DB ou non
RegisterNUICallback("close", function(_, cb)
    closeCreator()
    print("Creator close callback triggered")
     -- ✅ CORRIGÉ : le close est désormais géré côté client, on ne déclenche plus d'événement serveur pour ça
        -- TriggerServerEvent("kt_character:closeCreator") --- IGNORE ---
            print("Close event handled client-side, no server event triggered")
            print("NUI focus released, creator closed cleanly")
            print("Debug: Creator closed, NUI focus should be false, player unfrozen")
            
    cb("ok")
end)

-- Sauvegarde apparence (depuis /skin)
RegisterNUICallback("saveAppearance", function(data, cb)
    if not currentUniqueId then cb("error_no_character") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:updateAppearance", data)
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

-- FIX : l'UI est déjà fermée par Creator.tsx avant d'arriver ici
-- On s'assure juste que le ped est décongelé et on applique le skin
RegisterNetEvent("kt_character:created", function(character)
    debugLog("Personnage créé (event serveur): " .. character.firstname .. " " .. character.lastname, "INFO")
    currentUniqueId = character.unique_id

    -- S'assurer que le ped est bien décongelé (l'UI l'a déjà fait normalement)
    FreezeEntityPosition(PlayerPedId(), false)

    -- Appliquer le skin après le spawn Union
    Citizen.CreateThread(function()
        Wait(1500)
        ApplyFullAppearance(character)
    end)
end)

-- Réponse du serveur pour /skin : charger l'apparence actuelle dans l'UI
RegisterNetEvent("kt_character:skinEditData", function(skinData)
    debugLog("Données skin reçues pour édition", "INFO")
    SendNUIMessage({ type = "open", skinData = skinData })
end)

-- Ouvrir le creator depuis Union (quand noCharacters)
RegisterNetEvent("kt_character:openCreator", function()
    if nuiOpen then return end
    debugLog("Ouverture creator (demandée par Union)", "INFO")
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
end)

RegisterNetEvent("kt_character:error", function(msg)
    debugLog("Erreur serveur: " .. tostring(msg), "ERROR")
    SendNUIMessage({ type = "error", message = msg })
end)

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
-- INTÉGRATION UNION : ré-appliquer le skin après spawn
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("union:spawn:apply", function(characterData)
    if characterData and characterData.unique_id then
        currentUniqueId = characterData.unique_id
        debugLog("Union spawn détecté pour " .. characterData.unique_id .. ", skin en attente...", "INFO")
        Citizen.CreateThread(function()
            Wait(1500)
            ApplyFullAppearance(characterData)
        end)
    end
end)

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