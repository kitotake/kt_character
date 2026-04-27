-- kt_character/client/main.lua
-- FIX : union:spawn:apply NE rappelle plus ApplyFullAppearance ici.
--       union/client/modules/spawn/main.lua est l'UNIQUE responsable du spawn+skin.
--       Ce fichier ne gère que : Creator NUI, CharacterSelect NUI, fermeture NUI.

local VERSION         = "2.2.1"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CLEAN CLOSE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function closeCreator()
    if DestroyCharacterCam then DestroyCharacterCam() end
    FreezeEntityPosition(PlayerPedId(), false)
    SetNuiFocus(false, false)
    nuiOpen = false
    debugLog("Creator fermé", "INFO")
end

local function closeSelectionUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    nuiOpen = false
    debugLog("Sélection fermée", "INFO")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDES DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterCommand("character", function()
    if nuiOpen then return end
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
    debugLog("Creator ouvert (commande)", "INFO")
end, false)

RegisterCommand("skin", function()
    if nuiOpen then return end
    if not currentUniqueId then return end
    nuiOpen = true
    TriggerServerEvent("kt_character:requestSkinEdit", currentUniqueId)
    CreateCharacterCam()
    SetNuiFocus(true, true)
    debugLog("Skin mode ouvert", "INFO")
end, false)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS — CREATOR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("update", function(data, cb)
    Citizen.CreateThread(function() ApplyPreview(data) end)
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
    if HandleCameraControl then HandleCameraControl(data and data.action or "") end
    cb("ok")
end)

RegisterNUICallback("close", function(_, cb)
    closeCreator()
    SendNUIMessage({ type = "close" })
    cb("ok")
end)

RegisterNUICallback("saveAppearance", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:updateAppearance", data)
    cb("ok")
end)

RegisterNUICallback("saveOutfit", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:saveOutfit", data)
    cb("ok")
end)

RegisterNUICallback("getOutfits", function(_, cb)
    if not currentUniqueId then cb("error") return end
    TriggerServerEvent("kt_character:getOutfits", { unique_id = currentUniqueId })
    cb("ok")
end)

RegisterNUICallback("loadOutfit",   function(data, cb) TriggerServerEvent("kt_character:loadOutfit", data) cb("ok") end)
RegisterNUICallback("deleteOutfit", function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:deleteOutfit", data)
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACK — SÉLECTION DE PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("selectCharacter", function(data, cb)
    if not data or not data.charId then
        cb("error")
        return
    end
    debugLog("selectCharacter → characters:selectCharacter charId=" .. tostring(data.charId), "INFO")
    TriggerServerEvent("characters:selectCharacter", data.charId)
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS SERVEUR — CREATOR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    SendNUIMessage({ type = "setIdentifier", identifier = license, unique_id = currentUniqueId or "" })
end)

RegisterNetEvent("kt_character:created", function(character)
    currentUniqueId = character.unique_id
    FreezeEntityPosition(PlayerPedId(), false)
    -- FIX VITESSE : plus de Wait(1500) — l'apparence est déjà appliquée
    --               par union:spawn:apply qui sera déclenché par le serveur
    debugLog("Personnage créé: " .. (character.firstname or "?"), "INFO")
end)

RegisterNetEvent("kt_character:closeUI", function()
    closeCreator()
    SendNUIMessage({ type = "close" })
    debugLog("closeUI reçu", "INFO")
end)

RegisterNetEvent("kt_character:skinEditData", function(skinData)
    SendNUIMessage({ type = "open", skinData = skinData })
    debugLog("Skin data reçu", "INFO")
end)

RegisterNetEvent("kt_character:error", function(msg)
    SendNUIMessage({ type = "error", message = msg })
    debugLog("Erreur: " .. tostring(msg), "ERROR")
end)

RegisterNetEvent("kt_character:outfitSaved",   function(outfit)  SendNUIMessage({ type = "outfitSaved",   outfit  = outfit  }) end)
RegisterNetEvent("kt_character:outfitsList",   function(outfits) SendNUIMessage({ type = "outfitsList",   outfits = outfits }) end)
RegisterNetEvent("kt_character:outfitDeleted", function(id)      SendNUIMessage({ type = "outfitDeleted", id      = id      }) end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — SÉLECTION DE PERSONNAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- union/server/spawn/handler.lua → union:spawn:selectCharacter
RegisterNetEvent("union:spawn:selectCharacter", function(characters)
    if nuiOpen then return end
    debugLog(("union:spawn:selectCharacter reçu: %d perso(s)"):format(characters and #characters or 0), "INFO")
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = "openCharacterSelection",
        characters = characters or {},
        slots      = #(characters or {}) + 1,
    })
end)

-- union/client/characterManager.lua → characters:openSelection
RegisterNetEvent("characters:openSelection", function(data)
    if nuiOpen then return end
    local chars = data and data.characters or {}
    local slots = data and data.slots      or 3
    debugLog(("characters:openSelection reçu: %d perso(s)"):format(#chars), "INFO")
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = "openCharacterSelection",
        characters = chars,
        slots      = slots,
    })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — CREATOR (0 personnage)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function _openCreator()
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
    debugLog("Creator ouvert", "INFO")
end

RegisterNetEvent("union:spawn:noCharacters",  function() if not nuiOpen then _openCreator() end end)
RegisterNetEvent("kt_character:openCreator",  function() if not nuiOpen then _openCreator() end end)
RegisterNetEvent("characters:openCreation",   function() if not nuiOpen then _openCreator() end end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — SPAWN
-- FIX : on ferme juste la NUI, on N'applique PAS le skin ici.
--       union/client/modules/spawn/main.lua s'en charge.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("union:spawn:apply", function(characterData)
    if not characterData then return end

    -- Stocker l'unique_id pour les commandes /skin etc.
    currentUniqueId = characterData.unique_id

    -- Fermer la NUI si ouverte
    if nuiOpen then
        closeSelectionUI()
    end

    -- ⚠️ NE PAS appeler ApplyFullAppearance ici.
    --    union/client/modules/spawn/main.lua le fait déjà.
    debugLog("union:spawn:apply reçu → NUI fermée, skin géré par spawn/main.lua", "INFO")
end)

RegisterNetEvent("characters:doSpawn", function(charData)
    if not charData then return end
    currentUniqueId = charData.unique_id
    debugLog("characters:doSpawn → fermeture NUI", "INFO")
    if nuiOpen then closeSelectionUI() end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS — APPARENCE (reloadskin / outfit)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_appearance:apply", function(data)
    debugLog("kt_appearance:apply reçu", "INFO")
    Citizen.CreateThread(function() ApplyFullAppearance(data) end)
end)

RegisterNetEvent("kt_appearance:update", function(data)
    debugLog("kt_appearance:update reçu (compat)", "INFO")
    Citizen.CreateThread(function() ApplyFullAppearance(data) end)
end)

RegisterNetEvent("kt_character:applyOutfit", function(data)
    debugLog("kt_character:applyOutfit reçu", "INFO")
    ApplyOutfit(data)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CYCLE DE VIE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AddEventHandler("playerDropped", function()
    nuiOpen         = false
    currentUniqueId = nil
end)

Citizen.CreateThread(function()
    Wait(1000)
    debugLog("kt_character v" .. VERSION .. " chargé", "INFO")
end)