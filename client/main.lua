-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN v2.0.3
-- Fix : closeUI (type vs action) + freeze + /skin
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION         = "2.0.3"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HELPER : fermer proprement le creator (caméra + unfreeze + NUI focus)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function closeCreator()
    -- Détruire la caméra (inclut FreezeEntityPosition false interne)
    if DestroyCharacterCam then
        DestroyCharacterCam()
    end

    -- Force unfreeze sur le ped ACTUEL (le modèle peut avoir changé)
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

-- Déclenché par Creator.tsx quand l'utilisateur clique "Créer le personnage"
-- (nuiFetch("close") dans handleSubmit)
RegisterNUICallback("close", function(_, cb)
    closeCreator()
    cb("ok")
end)

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

-- Appelé par le serveur APRÈS création DB réussie
-- À ce moment l'UI est déjà fermée via kt_character:closeUI
-- On stocke juste le unique_id et on applique le skin
RegisterNetEvent("kt_character:created", function(character)
    debugLog("Personnage créé: " .. character.firstname .. " " .. character.lastname, "INFO")
    currentUniqueId = character.unique_id

    -- Sécurité : s'assurer que le ped est bien décongelé
    FreezeEntityPosition(PlayerPedId(), false)

    -- Appliquer le skin après le spawn Union (qui arrive via union:spawn:apply)
    Citizen.CreateThread(function()
        Wait(1500)
        ApplyFullAppearance(character)
    end)
end)

-- ✅ FIX PRINCIPAL : fermer le creator depuis le serveur
-- Le serveur envoie cet event juste après kt_character:created
-- CORRECTION : utiliser type = "close" (pas action = "close")
RegisterNetEvent("kt_character:closeUI", function()
    -- closeCreator gère : caméra + FreezeEntityPosition(false) + SetNuiFocus(false)
    closeCreator()
print("closeUI reçu → creator fermé")
    -- Dire au React de cacher le composant (type = "close", pas action)
    SendNUIMessage({ type = "close" })

    debugLog("closeUI reçu → creator fermé", "INFO")
end)

RegisterNetEvent("kt_character:skinEditData", function(skinData)
    debugLog("Données skin reçues pour édition", "INFO")
    SendNUIMessage({ type = "open", skinData = skinData })
end)

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
-- INTÉGRATION UNION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("union:spawn:apply", function(characterData)
    if characterData and characterData.unique_id then
        currentUniqueId = characterData.unique_id
        debugLog("Union spawn pour " .. characterData.unique_id .. ", skin en attente...", "INFO")
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
    debugLog("kt_character client v" .. VERSION .. " chargé", "INFO")
end)