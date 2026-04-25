-- kt_character/client/main.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT CHARACTER CREATOR - CLIENT MAIN v2.2.0
-- Compatible union framework (characterManager.lua)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local VERSION         = "2.2.0"
local DEBUG           = true
local nuiOpen         = false
local currentUniqueId = nil

local function debugLog(msg, level)
    if not DEBUG then return end
    print(("^2[kt_character:%s]^7 %s"):format(level or "INFO", msg))
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CLEAN CLOSE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function closeCreator()
    if DestroyCharacterCam then DestroyCharacterCam() end
    FreezeEntityPosition(PlayerPedId(), false)
    SetNuiFocus(false, false)
    nuiOpen = false
    debugLog("Creator fermé", "INFO")
end

local function closeSelectionUI()
    SetNuiFocus(false, false)
    -- Envoie action="close" pour fermer CharacterSelect dans App.tsx
    SendNUIMessage({ action = "close" })
    nuiOpen = false
    debugLog("Sélection fermée", "INFO")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDES DEBUG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS — CREATOR (kt_character)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

RegisterNUICallback("saveOutfit",   function(data, cb)
    if not currentUniqueId then cb("error") return end
    data.unique_id = currentUniqueId
    TriggerServerEvent("kt_character:saveOutfit", data)
    cb("ok")
end)

RegisterNUICallback("getOutfits",   function(_, cb)
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACK — SÉLECTION DE PERSONNAGE
--
-- CharacterSelect.tsx fait un fetch vers https://<resource>/selectCharacter
-- → ce callback le reçoit et relaie vers union (characters:selectCharacter)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNUICallback("selectCharacter", function(data, cb)
    if not data or not data.charId then
        cb("error")
        return
    end
    debugLog("selectCharacter → characters:selectCharacter charId=" .. tostring(data.charId), "INFO")
    -- On relaie vers le serveur union qui gère Character.select
    TriggerServerEvent("characters:selectCharacter", data.charId)
    cb("ok")
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS SERVEUR — CREATOR (kt_character)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RegisterNetEvent("kt_character:sendIdentifier", function(license)
    SendNUIMessage({ type = "setIdentifier", identifier = license, unique_id = currentUniqueId or "" })
end)

RegisterNetEvent("kt_character:created", function(character)
    currentUniqueId = character.unique_id
    FreezeEntityPosition(PlayerPedId(), false)
    Citizen.CreateThread(function()
        Wait(1500)
        ApplyFullAppearance(character)
    end)
    debugLog("Personnage créé: " .. character.firstname, "INFO")
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — SÉLECTION DE PERSONNAGE
--
-- union/server/spawn/handler.lua envoie union:spawn:selectCharacter
-- union/client/modules/character/characterManager.lua envoie characters:openSelection
-- On écoute les DEUX pour être robuste
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- union/server/spawn/handler.lua → union:spawn:selectCharacter (liste brute de chars)
RegisterNetEvent("union:spawn:selectCharacter", function(characters)
    if nuiOpen then return end
    debugLog(("union:spawn:selectCharacter reçu: %d perso(s)"):format(characters and #characters or 0), "INFO")
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = "openCharacterSelection",
        characters = characters or {},
        slots      = #(characters or {}) + 1, -- slots = personnages actuels + 1 libre
    })
end)

-- union/client/characterManager.lua → characters:openSelection (format {slots, characters})
RegisterNetEvent("characters:openSelection", function(data)
    if nuiOpen then return end
    local chars = data and data.characters or {}
    local slots = data and data.slots      or 3
    debugLog(("characters:openSelection reçu: %d perso(s), %d slot(s)"):format(#chars, slots), "INFO")
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = "openCharacterSelection",
        characters = chars,
        slots      = slots,
    })
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — CREATOR (aucun personnage)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- union/server/spawn/handler.lua → union:spawn:noCharacters
RegisterNetEvent("union:spawn:noCharacters", function()
    if nuiOpen then return end
    debugLog("union:spawn:noCharacters reçu → ouverture creator", "INFO")
    _openCreator()
end)

-- union/client/characterManager.lua → kt_character:openCreator
RegisterNetEvent("kt_character:openCreator", function()
    if nuiOpen then return end
    debugLog("kt_character:openCreator reçu", "INFO")
    _openCreator()
end)

-- characters:openCreation (envoyé par characterManager.lua côté serveur)
RegisterNetEvent("characters:openCreation", function(data)
    if nuiOpen then return end
    debugLog("characters:openCreation reçu", "INFO")
    -- kt_character:openCreator est déjà envoyé par characterManager en parallèle,
    -- mais on ouvre ici au cas où il ne serait pas envoyé.
    _openCreator()
end)

-- Fonction commune d'ouverture du creator
function _openCreator()
    nuiOpen = true
    TriggerServerEvent("kt_character:requestIdentifier")
    CreateCharacterCam()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open" })
    debugLog("Creator ouvert", "INFO")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — SPAWN (fermeture NUI après sélection)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- union envoie union:spawn:apply après sélection → ferme la NUI de sélection
RegisterNetEvent("union:spawn:apply", function(characterData)
    if not characterData then return end
    currentUniqueId = characterData.unique_id

    -- Ferme la NUI de sélection si ouverte
    if nuiOpen then
        closeSelectionUI()
    end

    -- L'apparence est appliquée par union/client/spawn/main.lua
    -- On attend que spawn/main.lua ait changé le modèle avant d'appliquer le skin
    Citizen.CreateThread(function()
        Wait(2000)
        if ApplyFullAppearance then
            ApplyFullAppearance(characterData)
        end
    end)
end)

-- characters:doSpawn (envoyé par characterManager si fallback BDD direct)
RegisterNetEvent("characters:doSpawn", function(charData)
    if not charData then return end
    currentUniqueId = charData.unique_id
    debugLog("characters:doSpawn reçu → fermeture NUI", "INFO")
    if nuiOpen then closeSelectionUI() end
    -- union:spawn:apply sera envoyé par le serveur ensuite
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS UNION — APPARENCE (kt_appearance)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CYCLE DE VIE
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

Citizen.CreateThread(function()
    Wait(1000)
    debugLog("kt_character v" .. VERSION .. " chargé", "INFO")
end)